# TensorFlow: Qwik Start || [GSP637](https://www.cloudskillsboost.google/focuses/7639?parent=catalog) ||

## Solution [here](https://youtu.be/Fx8csorAnSI)

### Run the following Commands in Jupyter notebook terminal

* Go to **Workbench** from [here](https://console.cloud.google.com/vertex-ai/workbench?)

```
pip3 install tensorflow
pip3 install --upgrade pip
pip install -U pylint --user
pip install -r requirements.txt
```

* Create & save the notebook as **model.ipynb**

```
import logging
import google.cloud.logging as cloud_logging
from google.cloud.logging.handlers import CloudLoggingHandler
from google.cloud.logging_v2.handlers import setup_logging

cloud_logger = logging.getLogger('cloudLogger')
cloud_logger.setLevel(logging.INFO)
cloud_logger.addHandler(CloudLoggingHandler(cloud_logging.Client()))
cloud_logger.addHandler(logging.StreamHandler())

import tensorflow as tf
import numpy as np

xs = np.array([-1.0, 0.0, 1.0, 2.0, 3.0, 4.0], dtype=float)
ys = np.array([-2.0, 1.0, 4.0, 7.0, 10.0, 13.0], dtype=float)

model = tf.keras.Sequential([tf.keras.layers.Dense(units=1, input_shape=[1])])

model.compile(optimizer=tf.keras.optimizers.SGD(), loss=tf.keras.losses.MeanSquaredError())

model.fit(xs, ys, epochs=500)

cloud_logger.info(str(model.predict(np.array([10.0]))))
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
