"""Classes of Baseera's obstacle model.

Every label is an ObstacleKind name in the app (app/lib/data/obstacles.dart),
so the app turns a detection straight into a warning ("كرسي على يمينك").
Keep the order: the exported model's class ids follow it, and so does
classes.txt for labelling your own photos.

Stage 1 glasses have only the camera, so this model is the only thing that
sees obstacles: "obstacle" covers things in the way that have no class of
their own (plant pots, sofas, beds, suitcases, fire hydrants). The camera can't
tell stairs going up from down; "stairs" is warned as a fall risk. Drops
(curbs, holes) need the downward distance sensor of the later glasses.
"""

LABELS = [
    "person",
    "bicycle",
    "car",
    "motorcycle",
    "bus",
    "dog",
    "chair",
    "bench",
    "table",
    "door",
    "stairs",
    "pole",
    "tree",
    "obstacle",
]

# COCO 2017 label -> ours. COCO boxes every one of its 80 classes in every
# image, so its images also teach the model what is NOT one of these.
COCO = {
    "person": "person",
    "bicycle": "bicycle",
    "car": "car",
    "truck": "car",
    "motorcycle": "motorcycle",
    "bus": "bus",
    "dog": "dog",
    "chair": "chair",
    "bench": "bench",
    "dining table": "table",
    # in the way, no class of their own
    "potted plant": "obstacle",
    "fire hydrant": "obstacle",
    "couch": "obstacle",
    "bed": "obstacle",
    "suitcase": "obstacle",
    # signs and meters stand on a pole
    "parking meter": "pole",
    "stop sign": "pole",
}

# Open Images V7 label -> ours, for what COCO lacks.
OPEN_IMAGES_TARGETS = {
    "Door": "door",
    "Stairs": "stairs",
    "Tree": "tree",
    "Street light": "pole",
}

# Also kept when they show up in those Open Images photos, so a person
# standing in a doorway isn't learned as background.
OPEN_IMAGES_ALSO = {
    "Person": "person",
    "Man": "person",
    "Woman": "person",
    "Boy": "person",
    "Girl": "person",
    "Car": "car",
    "Truck": "car",
    "Bicycle": "bicycle",
    "Motorcycle": "motorcycle",
    "Bus": "bus",
    "Dog": "dog",
    "Chair": "chair",
    "Bench": "bench",
    "Table": "table",
}

# Photos to download per source class. Doors and stairs matter most indoors
# and are rarer in public data, so they get more.
COCO_PER_CLASS = 1200
# The "obstacle" and extra "pole" sources need fewer each.
COCO_PER_CLASS_OVERRIDE = {
    "potted plant": 600,
    "fire hydrant": 600,
    "couch": 600,
    "bed": 400,
    "suitcase": 600,
    "parking meter": 500,
    "stop sign": 500,
}
OPEN_IMAGES_PER_CLASS = {
    "Door": 3000,
    "Stairs": 3000,
    "Tree": 1500,
    "Street light": 2000,
}
