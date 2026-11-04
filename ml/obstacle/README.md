# Obstacle model (glasses camera)

YOLO11n trained to spot what matters to someone walking with only the glasses:
people, bicycles, cars, motorcycles, buses, dogs, chairs, benches, tables,
doors, stairs, poles, trees, and general obstacles (plant pots, sofas, beds,
suitcases, fire hydrants). The phone runs it on the glasses' camera frames;
`app/lib/recognition/` turns each detection into a warning with a side
("كرسي على يمينك"): the phone says it, and the glasses vibrate with a pattern
for how urgent it is. Stage 1 glasses have only the camera, so this model is
what sees everything; drops (curbs, holes) wait for the later glasses'
downward distance sensor.

| File | What it is |
|---|---|
| `classes.py` | The model's labels (= the app's `ObstacleKind` names) and how COCO / Open Images labels map onto them |
| `build_dataset.py` | Downloads the photos (FiftyOne, no accounts) and writes a YOLO dataset |
| `train_obstacles.ipynb` | Colab notebook: dataset → train → evaluate → export. Generated — edit the scripts, then `python make_notebook.py` |
| `install_model.py` | Copies the exported model into `app/assets/model/` |

## Train (Google Colab)

1. Open `train_obstacles.ipynb` in Colab (File → Upload notebook).
2. Runtime → Change runtime type → **T4 GPU**.
3. Run all cells. First run ≈ 45 min dataset + 4–5 h training. If Colab
   disconnects, run again from the top: the dataset and the last checkpoint
   are on Drive, and training resumes.
4. Download `MyDrive/baseera/export` and install it:

   ```sh
   python ml/obstacle/install_model.py path/to/export
   ```

   Then rebuild the app. Without a model, stage 1 glasses give no obstacle
   warnings at all (they only stream the camera).

Step 1 of the notebook also exports the stock COCO YOLO11n to
`export/coco/` in a few minutes. Install that first to test with the real
glasses while the trained model is still training:

```sh
python ml/obstacle/install_model.py path/to/export/coco
```

## Add your own glasses photos (do this once the glasses exist)

Public photos are sharp phone pictures; the glasses camera is small, noisy
and wide-angle. A few hundred labelled photos taken *through the glasses*
make the biggest difference.

1. Take photos with the glasses (indoors, outdoors, doors, stairs, people…).
2. Label them in Roboflow or CVAT with the classes from `classes.txt` (the
   notebook writes it next to the dataset; same order as `classes.py`),
   export as YOLO.
3. Put the export in `MyDrive/baseera/glasses_photos/` (`images/`, `labels/`),
   delete `MyDrive/baseera/obstacles_dataset.zip` and
   `MyDrive/baseera/runs/obstacles`, and run the notebook again.

## License

Ultralytics YOLO is AGPL-3.0. Fine for this project as delivered (the client
gets the source); a closed-source commercial release would need an
Ultralytics Enterprise license. COCO and Open Images annotations are CC BY 4.0.
