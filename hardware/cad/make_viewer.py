"""Turns out/model.json into a 3D viewer and still renders.

  out/Baseera_Glasses_3D.html   one self-contained file: open it in Edge or
                                Chrome, drag to turn the glasses, scroll to zoom
  out/renders/*.png             stills for documents (with --shots)

Run after baseera_glasses.py:  python make_viewer.py [--shots]
"""

import base64
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
VENDOR = HERE / "vendor"
FONTS = (HERE / "../../app/assets/fonts").resolve()
EDGE = Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
EDGE_PROFILE = (HERE / "../../app/build/tmp/edge-profile").resolve()

LEGEND = {  # matches LABELS in baseera_glasses.py
    1: "المتحكم والكاميرا",
    2: "حساس المسافة الأمامي",
    3: "حساس الأرض",
    4: "السماعة ومضخم الصوت",
    5: "وحدة الاهتزاز",
    6: "البطارية",
    7: "زر التحكم",
    8: "مفتاح التشغيل",
    9: "الهيكل المطبوع",
    10: "وحدة الشحن",
    11: "منفذ USB-C للمتحكم",
    12: "منفذ USB-C للشحن",
    13: "مسار الأسلاك",
}

SHOTS = {  # name: (width, height) in CSS px; rendered at 2x
    "hero": (1500, 900),
    "xray": (1500, 1000),
    "fit_right": (1500, 860),
    "fit_left": (1500, 860),
}

PAGE = r"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>بصيرة: نموذج النظارة</title>
<style>
@font-face { font-family: Plex; font-weight: 400; src: url(data:font/ttf;base64,__FONT400__); }
@font-face { font-family: Plex; font-weight: 600; src: url(data:font/ttf;base64,__FONT600__); }
:root { --blue: #1D3B8B; --amber: #F5A524; --ink: #0E1630; --muted: #5A6280;
  --bg: #F6F7FB; --line: #E1E5F0; --card: #FFFFFF; }
html, body { margin: 0; height: 100%; overflow: hidden; background: var(--bg);
  font-family: Plex, "Segoe UI", Tahoma, sans-serif; color: var(--ink); }
canvas { display: block; touch-action: none; }
header { position: absolute; top: 20px; right: 24px; max-width: 60%; }
header h1 { margin: 0; font-size: 22px; font-weight: 600; color: var(--blue); }
header p { margin: 4px 0 0; font-size: 14px; color: var(--muted); }
.modes { position: absolute; top: 20px; left: 24px; display: flex; gap: 4px; padding: 4px;
  background: var(--card); border: 1px solid var(--line); border-radius: 12px; }
.modes button { font: inherit; font-size: 14px; border: 0; background: transparent; color: var(--muted);
  padding: 8px 14px; border-radius: 9px; cursor: pointer; }
.modes button.on { background: var(--blue); color: #fff; }
.legend { position: absolute; right: 24px; bottom: 24px; background: var(--card); border: 1px solid var(--line);
  border-radius: 14px; padding: 10px 16px; font-size: 14px; line-height: 2; display: none; }
.legend.show { display: block; }
.num { display: inline-flex; width: 22px; height: 22px; border-radius: 50%; background: var(--amber);
  color: var(--ink); font: 600 12px "Segoe UI", Tahoma, sans-serif; align-items: center; justify-content: center;
  margin-left: 8px; vertical-align: middle; }
.hint { position: absolute; bottom: 22px; left: 24px; font-size: 13px; color: var(--muted); }
#leaders { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; }
#badges { position: absolute; inset: 0; pointer-events: none; }
.badge { position: absolute; width: 30px; height: 30px; margin: -15px 0 0 -15px; border-radius: 50%;
  background: var(--amber); color: var(--ink); border: 2.5px solid #fff; box-sizing: border-box;
  display: flex; align-items: center; justify-content: center; font: 700 15px "Segoe UI", Tahoma, sans-serif;
  box-shadow: 0 1px 5px rgba(14, 22, 48, .3); }
body.shot header, body.shot .modes, body.shot .legend, body.shot .hint { display: none; }
body.shot .badge { width: 38px; height: 38px; margin: -19px 0 0 -19px; font-size: 19px; border-width: 3px; }
@media (max-width: 640px) {
  header { right: 16px; top: 16px; } header h1 { font-size: 18px; }
  .modes { top: auto; bottom: 16px; left: 16px; right: 16px; justify-content: center; }
  .legend { right: 16px; left: 16px; bottom: 76px; font-size: 13px; }
  .hint { display: none; }
}
</style>
</head>
<body>
<header><h1>بصيرة · النظارة الذكية</h1><p>نموذج ثلاثي الأبعاد، الإصدار الأول</p></header>
<div class="modes">
  <button data-mode="solid" class="on">الشكل الخارجي</button>
  <button data-mode="xray">المكونات من الداخل</button>
</div>
<div class="legend">__LEGEND__</div>
<div class="hint">اسحب لتدوير النظارة، ومرّر للتكبير</div>
<svg id="leaders"></svg>
<div id="badges"></div>
<script>__THREE__</script>
<script>__ORBIT__</script>
<script>__ROOM__</script>
<script>
const MODEL = __MODEL__;
const params = new URLSearchParams(location.search);
const shot = params.get('shot');
if (shot) document.body.classList.add('shot');
THREE.ColorManagement.legacyMode = false;   // hex colours are sRGB

const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(innerWidth, innerHeight);
renderer.outputEncoding = THREE.sRGBEncoding;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
document.body.prepend(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(shot ? '#FFFFFF' : '#F6F7FB');
const pmrem = new THREE.PMREMGenerator(renderer);
scene.environment = pmrem.fromScene(new THREE.RoomEnvironment(), 0.04).texture;

// The model is Z-up (X right, Y forward); three.js is Y-up.
const root = new THREE.Group();
root.rotation.x = -Math.PI / 2;
scene.add(root);
const P = (x, y, z) => new THREE.Vector3(x, z, -y);   // model mm -> world

function decode(s, T) {
  const bin = atob(s), buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return new T(buf.buffer);
}

const METAL = /shield|usbc|motor|battery|screw|pins|legs/;
const printed = [];
for (const p of MODEL.parts) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(decode(p.pos, Float32Array), 3));
  g.setIndex(new THREE.BufferAttribute(decode(p.idx, Uint32Array), 1));
  g.computeVertexNormals();
  let mat;
  if (p.group === 'print') {
    mat = new THREE.MeshPhysicalMaterial({ color: p.color, roughness: 0.5, metalness: 0,
      clearcoat: 0.3, clearcoatRoughness: 0.45, side: THREE.DoubleSide });
  } else if (p.group === 'lens') {
    mat = new THREE.MeshPhysicalMaterial({ color: p.color, roughness: 0.05, transparent: true,
      opacity: 0.6, depthWrite: false, side: THREE.DoubleSide });
  } else if (p.group === 'pad') {
    mat = new THREE.MeshPhysicalMaterial({ color: p.color, roughness: 0.35, transparent: true, opacity: 0.22 });
  } else {
    const metal = METAL.test(p.name);
    mat = new THREE.MeshStandardMaterial({ color: p.color, roughness: metal ? 0.3 : 0.55,
      metalness: metal ? 0.8 : 0.05, side: THREE.DoubleSide });
  }
  const m = new THREE.Mesh(g, mat);
  m.castShadow = p.group !== 'lens';
  m.receiveShadow = true;
  m.userData = p;
  root.add(m);
  if (p.group === 'print') {
    const edges = new THREE.LineSegments(new THREE.EdgesGeometry(g, 30),
      new THREE.LineBasicMaterial({ color: '#1D3B8B', transparent: true, opacity: 0.6 }));
    edges.visible = false;
    m.add(edges);
    printed.push({ mesh: m, solid: mat, edges,
      ghost: new THREE.MeshBasicMaterial({ color: '#8FA0D0', transparent: true, opacity: 0.14,
        depthWrite: false, side: THREE.DoubleSide }) });
  }
}

root.updateMatrixWorld(true);
const bounds = new THREE.Box3().setFromObject(root);
const centre = bounds.getCenter(new THREE.Vector3());

scene.add(new THREE.HemisphereLight('#FFFFFF', '#D5D9E4', 0.55));
const key = new THREE.DirectionalLight('#FFFFFF', 1.5);
key.position.copy(centre).add(new THREE.Vector3(-160, 320, 180));
key.target.position.copy(centre);
key.castShadow = true;
key.shadow.mapSize.set(2048, 2048);
Object.assign(key.shadow.camera, { left: -220, right: 220, top: 220, bottom: -220, near: 10, far: 900 });
key.shadow.bias = -0.0004;
key.shadow.radius = 4;
scene.add(key, key.target);
const ground = new THREE.Mesh(new THREE.PlaneGeometry(2000, 2000),
  new THREE.ShadowMaterial({ opacity: 0.13 }));
ground.rotation.x = -Math.PI / 2;
ground.position.y = bounds.min.y - 0.5;
ground.receiveShadow = true;
scene.add(ground);

const VIEWS = {   // camera position and target, in model mm
  hero: [[-190, 215, 95], [0, -38, 0]],
  xray: [[-175, 190, 140], [0, -38, -2]],
  fit_right: [[330, -33, 11], [83, -33, 11]],    // right housing seen through its lid
  fit_left: [[-330, -33, 11], [-83, -33, 11]],
};
const HIDE = { fit_right: 'left', fit_left: 'right' };   // the far housing would show through
const camera = new THREE.PerspectiveCamera(28, innerWidth / innerHeight, 1, 5000);
function setView(name) {
  const [pos, target] = VIEWS[name];
  camera.position.copy(P(...pos));
  controls.target.copy(P(...target));
  controls.update();
}
const controls = new THREE.OrbitControls(camera, renderer.domElement);
controls.enableDamping = !shot;
controls.minDistance = 120;
controls.maxDistance = 900;

let mode = 'solid';
function setMode(m) {
  mode = m;
  for (const p of printed) {
    p.mesh.material = m === 'xray' ? p.ghost : p.solid;
    p.edges.visible = m === 'xray';
    p.mesh.castShadow = m !== 'xray';
  }
  for (const o of root.children) {
    if (o.userData.group === 'lens' || o.userData.group === 'pad') o.visible = m !== 'xray';
    if (o.userData.group === 'elec' || o.userData.group === 'wire') o.castShadow = m !== 'xray';
  }
  ground.visible = m !== 'xray';
  document.querySelectorAll('.modes button').forEach(b => b.classList.toggle('on', b.dataset.mode === m));
  document.querySelector('.legend').classList.toggle('show', m === 'xray');
  drawLabels();
}
document.querySelectorAll('.modes button').forEach(b => b.addEventListener('click', () => setMode(b.dataset.mode)));

const badges = document.getElementById('badges');
const leaders = document.getElementById('leaders');
const NUDGE = __NUDGE__;
function toScreen(v) {
  const p = v.clone().project(camera);
  return [(p.x + 1) / 2 * innerWidth, (1 - p.y) / 2 * innerHeight];
}
function drawLabels() {
  badges.innerHTML = '';
  leaders.innerHTML = '';
  if (mode !== 'xray') return;
  const view = shot || 'live';
  const [cx, cy] = toScreen(centre);
  for (const [n, label] of Object.entries(MODEL.labels)) {
    const part = root.children.find(o => o.userData.name === label.part);
    if (part && !part.visible) continue;
    if ((NUDGE[view] || {})[n] === null) continue;
    const [ax, ay] = toScreen(P(...label.at));
    let dx = ax - cx, dy = ay - cy;
    const len = Math.hypot(dx, dy) || 1;
    const push = Math.min(innerWidth, innerHeight) * 0.075;
    let bx = ax + dx / len * push, by = ay + dy / len * push;
    const nudge = (NUDGE[view] || {})[n];
    if (nudge === null) continue;   // label not wanted in this view
    if (nudge) { bx += nudge[0]; by += nudge[1]; }
    leaders.insertAdjacentHTML('beforeend',
      `<line x1="${ax}" y1="${ay}" x2="${bx}" y2="${by}" stroke="#0E1630" stroke-width="1.4" stroke-opacity=".55"/>` +
      `<circle cx="${ax}" cy="${ay}" r="3" fill="#0E1630" fill-opacity=".7"/>`);
    const b = document.createElement('div');
    b.className = 'badge';
    b.style.left = bx + 'px';
    b.style.top = by + 'px';
    b.textContent = n;
    badges.appendChild(b);
  }
}

function render() { renderer.render(scene, camera); drawLabels(); }
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
  render();
});

if (shot) {
  setView(shot);
  if (HIDE[shot]) for (const o of root.children) if (o.userData.side === HIDE[shot]) o.visible = false;
  setMode(shot === 'xray' || HIDE[shot] ? 'xray' : 'solid');
  render();
  document.title = 'ready';
} else {
  setView('hero');
  setMode('solid');
  (function loop() { requestAnimationFrame(loop); controls.update(); render(); })();
}
</script>
</body>
</html>
"""

NUDGE = {"xray": {"8": [-10, -95], "6": [55, -25], "2": [75, -45], "3": [45, 5], "10": [-20, 75], "12": [-75, -35], "11": [-30, -40], "5": [-20, -25]}, "fit_right": {"13": None}, "fit_left": {"13": None}, "live": {}}


def build_page() -> Path:
    model = json.loads((OUT / "model.json").read_text(encoding="utf-8"))
    legend = "".join(f'<div><span class="num">{n}</span>{t}</div>' for n, t in LEGEND.items())
    font = lambda name: base64.b64encode((FONTS / name).read_bytes()).decode()
    page = (PAGE
            .replace("__FONT400__", font("IBMPlexSansArabic-Regular.ttf"))
            .replace("__FONT600__", font("IBMPlexSansArabic-SemiBold.ttf"))
            .replace("__LEGEND__", legend)
            .replace("__NUDGE__", json.dumps(NUDGE))
            .replace("__THREE__", (VENDOR / "three.min.js").read_text(encoding="utf-8"))
            .replace("__ORBIT__", (VENDOR / "OrbitControls.js").read_text(encoding="utf-8"))
            .replace("__ROOM__", (VENDOR / "RoomEnvironment.js").read_text(encoding="utf-8"))
            .replace("__MODEL__", json.dumps(model)))
    path = OUT / "Baseera_Glasses_3D.html"
    path.write_text(page, encoding="utf-8")
    print(f"{path.name}: {path.stat().st_size // 1024} KB")
    return path


def crop_white(png: Path, margin: int = 40) -> None:
    from PIL import Image, ImageChops
    im = Image.open(png).convert("RGB")
    diff = ImageChops.difference(im, Image.new("RGB", im.size, (255, 255, 255)))
    box = diff.point(lambda v: 255 if v > 6 else 0).getbbox()
    if box:
        l, t, r, b = box
        im.crop((max(l - margin, 0), max(t - margin, 0), min(r + margin, im.width),
                 min(b + margin, im.height))).save(png)


def render_shots(page: Path) -> None:
    (OUT / "renders").mkdir(exist_ok=True)
    EDGE_PROFILE.mkdir(parents=True, exist_ok=True)
    for name, (w, h) in SHOTS.items():
        png = OUT / "renders" / f"{name}.png"
        png.unlink(missing_ok=True)
        subprocess.run([
            str(EDGE), "--headless=new", "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
            "--no-first-run", f"--user-data-dir={EDGE_PROFILE}", "--hide-scrollbars",
            "--force-device-scale-factor=2", f"--window-size={w},{h}",
            "--virtual-time-budget=20000", f"--screenshot={png}", page.as_uri() + f"?shot={name}",
        ], check=True, capture_output=True, timeout=300)
        assert png.exists(), f"{png} was not written"
        crop_white(png)
        print(f"{png.name}: {png.stat().st_size // 1024} KB")


if __name__ == "__main__":
    page = build_page()
    if "--shots" in sys.argv:
        render_shots(page)
