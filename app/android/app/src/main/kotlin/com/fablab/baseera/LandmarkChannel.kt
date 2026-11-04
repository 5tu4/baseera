package com.fablab.baseera

import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

/**
 * Runs MediaPipe hand + pose landmarkers on camera frames sent from Flutter
 * and returns only the landmarks. Same models as the training pipeline
 * (ml/extract.py), so the phone sees the numbers the model was trained on.
 */
class LandmarkChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "baseera/landmarks")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var hands: HandLandmarker? = null
    private var pose: PoseLandmarker? = null
    private var lastTimestamp = 0L
    private val buffers = mutableMapOf<String, ByteBuffer>()
    private var loaderUsed = "-"

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> runOnWorker(result) { ensureModels(); true }
            "detect" -> runOnWorker(result) { detect(call) }
            "info" -> runOnWorker(result) { deviceInfo() }
            "close" -> runOnWorker(result) { close(); null }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.execute { close() }
        worker.shutdown()
    }

    private fun runOnWorker(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Throwable) {
                // Many of these carry no message (UnsatisfiedLinkError and
                // friends), so name the type too or the app can only report
                // "null" back to us.
                Log.e("LandmarkChannel", "landmark call failed", e)
                val cause = generateSequence(e) { it.cause }.last()
                val detail = listOfNotNull(
                    e.javaClass.simpleName,
                    e.message,
                    if (cause !== e) "caused by ${cause.javaClass.simpleName}: ${cause.message}" else null,
                ).joinToString(": ")
                main.post { result.error("landmarks", detail, null) }
            }
        }
    }

    private fun assetBytes(name: String): ByteArray {
        val key = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("assets/mediapipe/$name")
        return context.assets.open(key).use { it.readBytes() }
    }

    /**
     * Unpacks a model into app storage once so MediaPipe can open it by path.
     * A path is steadier than handing over an in-memory buffer, which the
     * garbage collector may move or free while native code still holds it.
     */
    private fun modelPath(name: String): String {
        val target = File(context.filesDir, "mediapipe/$name")
        val bytes = assetBytes(name)
        if (!target.exists() || target.length() != bytes.size.toLong()) {
            target.parentFile?.mkdirs()
            target.writeBytes(bytes)
        }
        return target.absolutePath
    }

    /** Direct buffer, kept referenced for as long as the landmarker lives. */
    private fun modelBuffer(name: String): ByteBuffer {
        val bytes = assetBytes(name)
        val buffer = ByteBuffer.allocateDirect(bytes.size)
            .order(ByteOrder.nativeOrder()).apply {
                put(bytes)
                rewind()
            }
        buffers[name] = buffer
        return buffer
    }

    /**
     * Builds base options from the file on disk, falling back to a buffer.
     * Some devices refuse one route and accept the other, and a tester can
     * see which was used in the app's diagnostics box.
     */
    private fun <T> withModel(name: String, create: (BaseOptions) -> T): T {
        return try {
            val options = BaseOptions.builder().setModelAssetPath(modelPath(name)).build()
            create(options).also { loaderUsed = "file" }
        } catch (fromFile: Throwable) {
            Log.w("LandmarkChannel", "loading $name by path failed, trying a buffer", fromFile)
            val options = BaseOptions.builder().setModelAssetBuffer(modelBuffer(name)).build()
            create(options).also { loaderUsed = "buffer (path failed: ${fromFile.javaClass.simpleName})" }
        }
    }

    private fun ensureModels() {
        if (hands == null) {
            hands = withModel("hand_landmarker.task") { base ->
                HandLandmarker.createFromOptions(
                    context,
                    HandLandmarker.HandLandmarkerOptions.builder()
                        .setBaseOptions(base)
                        .setRunningMode(RunningMode.VIDEO)
                        .setNumHands(2)
                        .setMinHandDetectionConfidence(0.3f)
                        .setMinHandPresenceConfidence(0.3f)
                        .setMinTrackingConfidence(0.3f)
                        .build()
                )
            }
        }
        if (pose == null) {
            pose = withModel("pose_landmarker_lite.task") { base ->
                PoseLandmarker.createFromOptions(
                    context,
                    PoseLandmarker.PoseLandmarkerOptions.builder()
                        .setBaseOptions(base)
                        .setRunningMode(RunningMode.VIDEO)
                        .setNumPoses(1)
                        .build()
                )
            }
        }
    }

    /** Shown in the app's diagnostics dialog, so testers can report a cause. */
    private fun deviceInfo(): Map<String, Any?> = mapOf(
        "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
        "android" to "${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})",
        "cpu" to Build.SUPPORTED_ABIS.joinToString(", "),
        "landmarkers" to if (hands != null && pose != null) "loaded" else "not loaded",
        "model loader" to loaderUsed,
    )

    private fun close() {
        hands?.close()
        pose?.close()
        hands = null
        pose = null
    }

    private fun detect(call: MethodCall): Map<String, Any?> {
        ensureModels()
        val bitmap = yuvToUprightBitmap(
            y = call.argument<ByteArray>("y")!!,
            u = call.argument<ByteArray>("u")!!,
            v = call.argument<ByteArray>("v")!!,
            width = call.argument<Int>("width")!!,
            height = call.argument<Int>("height")!!,
            yRowStride = call.argument<Int>("yRowStride")!!,
            uvRowStride = call.argument<Int>("uvRowStride")!!,
            uvPixelStride = call.argument<Int>("uvPixelStride")!!,
            rotation = call.argument<Int>("rotation")!!,
        )
        // VIDEO mode needs strictly increasing timestamps.
        val timestamp = maxOf(SystemClock.uptimeMillis(), lastTimestamp + 1)
        lastTimestamp = timestamp
        val image = BitmapImageBuilder(bitmap).build()
        val poseResult = pose!!.detectForVideo(image, timestamp)
        val handResult = hands!!.detectForVideo(image, timestamp)

        return mapOf(
            "width" to bitmap.width,
            "height" to bitmap.height,
            "pose" to poseResult.landmarks().firstOrNull()?.let { points ->
                DoubleArray(points.size * 2) { i ->
                    val p = points[i / 2]
                    (if (i % 2 == 0) p.x() else p.y()).toDouble()
                }
            },
            "hands" to handResult.landmarks().take(2).map { points ->
                DoubleArray(points.size * 2) { i ->
                    val p = points[i / 2]
                    (if (i % 2 == 0) p.x() else p.y()).toDouble()
                }
            },
        )
    }

    /**
     * YUV_420_888 planes -> ARGB bitmap at half resolution, rotated upright.
     * Half resolution keeps conversion fast and matches the training frames'
     * scale (KArSL frames are 256x256).
     */
    private fun yuvToUprightBitmap(
        y: ByteArray, u: ByteArray, v: ByteArray,
        width: Int, height: Int,
        yRowStride: Int, uvRowStride: Int, uvPixelStride: Int,
        rotation: Int,
    ): Bitmap {
        val sw = width / 2
        val sh = height / 2
        val sideways = rotation == 90 || rotation == 270
        val ow = if (sideways) sh else sw
        val oh = if (sideways) sw else sh
        val out = IntArray(ow * oh)
        for (sy in 0 until sh) {
            val y0 = sy * 2
            val uvRow = (y0 / 2) * uvRowStride
            for (sx in 0 until sw) {
                val x0 = sx * 2
                val luma = y[y0 * yRowStride + x0].toInt() and 0xff
                val uvIndex = uvRow + (x0 / 2) * uvPixelStride
                val cb = (u[uvIndex].toInt() and 0xff) - 128
                val cr = (v[uvIndex].toInt() and 0xff) - 128
                val r = (luma + ((cr * 1436) shr 10)).coerceIn(0, 255)
                val g = (luma - ((cb * 352 + cr * 731) shr 10)).coerceIn(0, 255)
                val b = (luma + ((cb * 1815) shr 10)).coerceIn(0, 255)
                val dx: Int
                val dy: Int
                when (rotation) {
                    90 -> { dx = sh - 1 - sy; dy = sx }
                    180 -> { dx = sw - 1 - sx; dy = sh - 1 - sy }
                    270 -> { dx = sy; dy = sw - 1 - sx }
                    else -> { dx = sx; dy = sy }
                }
                out[dy * ow + dx] = (0xff shl 24) or (r shl 16) or (g shl 8) or b
            }
        }
        return Bitmap.createBitmap(out, ow, oh, Bitmap.Config.ARGB_8888)
    }
}
