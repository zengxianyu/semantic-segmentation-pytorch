# Semantic Segmentation on MIT ADE20K dataset in PyTorch

This is a PyTorch implementation of semantic segmentation models on MIT ADE20K scene parsing dataset.

ADE20K is the largest open source dataset for semantic segmentation and scene parsing, released by MIT Computer Vision team. Follow the link below to find the repository for our dataset and implementations on Caffe and Torch7:
https://github.com/CSAILVision/sceneparsing

All pretrained models can be found at:
http://sceneparsing.csail.mit.edu/model/pytorch

<img src="./teaser/ADE_val_00000278.png" width="900"/>
<img src="./teaser/ADE_val_00001519.png" width="900"/>
[From left to right: Test Image, Ground Truth, Predicted Result]

## Highlights

### Syncronized Batch Normalization on PyTorch
This module computes the mean and standard-deviation across all devices during training. We empirically find that a reasonable large batch size is important for segmentation. We thank [Jiayuan Mao](http://vccy.xyz/) for his kind contributions, please refer to [Synchronized-BatchNorm-PyTorch](https://github.com/vacancy/Synchronized-BatchNorm-PyTorch) for details.

The implementation is easy to use as:
- It is pure-python, no C++ extra extension libs.
- It is completely compatible with PyTorch's implementation. Specifically, it uses unbiased variance to update the moving average, and use sqrt(max(var, eps)) instead of sqrt(var + eps).
- It is efficient, only 20% to 30% slower than UnsyncBN.

### Dynamic scales of input for training with multiple GPUs 
For the task of semantic segmentation, it is good to keep aspect ratio of images during training. So we re-implement the `DataParallel` module, and make it support distributing data to multiple GPUs in python dict, so that each gpu can process images of different sizes. At the same time, the dataloader also operates differently. 

<sup>*Now the batch size of a dataloader always equals to the number of GPUs*, each element will be sent to a GPU. It is also compatible with multi-processing. Note that the file index for the multi-processing dataloader is stored on the master process, which is in contradict to our goal that each worker maintains its own file list. So we use a trick that although the master process still gives dataloader an index for `__getitem__` function, we just ignore such request and send a random batch dict. Also, *the multiple workers forked by the dataloader all have the same seed*, you will find that multiple workers will yield exactly the same data, if we use the above-mentioned trick directly. Therefore, we add one line of code which sets the defaut seed for `numpy.random` before activating multiple worker in dataloader.</sup>

### An Efficient and Effective Framework: UPerNet
UPerNet is a model based on Feature Pyramid Network (FPN) and Pyramid Pooling Module (PPM). It doesn't need dilated convolution, an operator that is time-and-memory consuming. *Without bells and whistles*, it is comparable or even better compared with PSPNet, while requiring much shorter training time and less GPU memory (e.g., you cannot train a PSPNet-101 on TITAN Xp GPUs with only 12GB memory, while you can train a UPerNet-101 on such GPUs). Thanks to the efficient network design, we will soon open source stronger models of UPerNet based on ResNeXt that is able to run on normal GPUs. Please refer to [UperNet](https://arxiv.org/abs/1807.10221) for details.


## Supported models
We split our models into encoder and decoder, where encoders are usually modified directly from classification networks, and decoders consist of final convolutions and upsampling.

Encoder:
- MobileNetV2dilated
- ResNet18dilated
- ResNet50dilated
- ResNet101dilated

***Coming soon***:
- ResNeXt101dilated

Decoder:
- C1 (1 convolution module)
- C1_deepsup (C1 + deep supervision trick)
- PPM (Pyramid Pooling Module, see [PSPNet](https://hszhao.github.io/projects/pspnet) paper for details.)
- PPM_deepsup (PPM + deep supervision trick)
- UPerNet (Pyramid Pooling + FPN head, see [UperNet](https://arxiv.org/abs/1807.10221) for details.)

## Performance:
IMPORTANT: We use our self-trained base model on ImageNet. The model takes the input in BGR form (consistent with opencv) instead of RGB form as used by default implementation of PyTorch. The base model will be automatically downloaded when needed.

<table><tbody>
    <th valign="bottom">Architecture</th>
    <th valign="bottom">MS Test</th>
    <th valign="bottom">Mean IoU</th>
    <th valign="bottom">Pixel Accuracy</th>
    <th valign="bottom">Overall Score</th>
    <th valign="bottom">Training Time</th>
    <tr>
        <td rowspan="2">MobileNetV2dilated + C1_deepsup</td>
        <td>No</td><td>32.39</td><td>75.75</td><td>54.07</td>
        <td rowspan="2">0.8 * 20 = 16 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>33.75</td><td>76.75</td><td>55.25</td>
    </tr>
    <tr>
        <td rowspan="2">ResNet18dilated + C1_deepsup</td>
        <td>No</td><td>33.82</td><td>76.05</td><td>54.94</td>
        <td rowspan="2">0.42 * 20 = 8.4 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>35.34</td><td>77.41</td><td>56.38</td>
    </tr>
    <tr>
        <td rowspan="2">ResNet18dilated + PPM_deepsup</td>
        <td>No</td><td>38.00</td><td>78.64</td><td>58.32</td>
        <td rowspan="2">1.1 * 20 = 22.0 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>38.81</td><td>79.29</td><td>59.05</td>
    </tr>
    <tr>
        <td rowspan="2">ResNet50dilated + C1_deepsup</td>
        <td>No</td><td>34.88</td><td>76.54</td><td>55.71</td>
        <td rowspan="2">1.38 * 20 = 27.6 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>35.49</td><td>77.53</td><td>56.66</td>
    </tr>
    <tr>
        <td rowspan="2">ResNet50dilated + PPM_deepsup</td>
        <td>No</td><td>41.26</td><td>79.73</td><td>60.50</td>
        <td rowspan="2">1.67 * 20 = 33.4 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>42.04</td><td>80.23</td><td>61.14</td>
    </tr>
    <tr>
        <td rowspan="2">ResNet101dilated + PPM_deepsup</td>
        <td>No</td><td>42.19</td><td>80.59</td><td>61.39</td>
        <td rowspan="2">3.82 * 25 = 95.5 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>42.53</td><td>80.91</td><td>61.72</td>
    </tr>
    <tr>
        <td rowspan="2"><b>UperNet50</b></td>
        <td>No</td><td>40.44</td><td>79.80</td><td>60.12</td>
        <td rowspan="2">1.75 * 20 = 35.0 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>41.55</td><td>80.23</td><td>60.89</td>
    </tr>
    <tr>
        <td rowspan="2"><b>UperNet101</b></td>
        <td>No</td><td>41.98</td><td>80.63</td><td>61.34</td>
        <td rowspan="2">2.5 * 25 = 62.5 hours</td>
    </tr>
    <tr>
        <td>Yes</td><td>42.66</td><td>81.01</td><td>61.84</td>
    </tr>
    <tr>
        <td>UPerNet-ResNext101 (coming soon!)</td>
        <td>-</td><td>-</td><td>-</td><td>-</td>
        <td>- hours</td>
    </tr>
</tbody></table>

The speed is benchmarked on a server with 8 NVIDIA Pascal Titan Xp GPUs (12GB GPU memory), ***except for*** ResNet101dilated, which is benchmarked on a server with 8 NVIDIA Tesla P40 GPUS (22GB GPU memory), because of the insufficient memory issue when using dilated conv on a very deep network.

## Environment
The code is developed under the following configurations.
- Hardware: 1-8 GPUs (with at least 12G GPU memories) (change ```[--num_gpus NUM_GPUS]``` accordingly)
- Software: Ubuntu 16.04.3 LTS, ***CUDA>=8.0, Python>=3.5, PyTorch>=0.4.0***

## Quick start: Test on an image using our trained model 
1. Here is a simple demo to do inference on a single image:
```bash
chmod +x demo_test.sh
./demo_test.sh
```
This script downloads a trained model (ResNet50dilated + PPM_deepsup) and a test image, runs the test script, and saves predicted segmentation (.png) to the working directory.

2. To test on multiple images, you can simply do something as the following (```$PATH_IMG1, $PATH_IMG2, $PATH_IMG3```are your image paths):
```
python3 -u test.py \
  --model_path $MODEL_PATH \
  --test_imgs $PATH_IMG1 $PATH_IMG2 $PATH_IMG3 \
  --arch_encoder resnet50dilated \
  --arch_decoder ppm_deepsup
```

3. See full input arguments via ```python3 test.py -h```.

## Training
1. Download the ADE20K scene parsing dataset:
```bash
chmod +x download_ADE20K.sh
./download_ADE20K.sh
```
2. Train a model (default: ResNet50dilated + PPM_deepsup). During training, checkpoints will be saved in folder ```ckpt```.
```bash
python3 train.py --num_gpus NUM_GPUS
```

For example:

* Train MobileNetV2dilated + C1_deepsup
```bash
python3 train.py \
    --num_gpus NUM_GPUS --arch_encoder mobilenetv2dilated --arch_decoder c1_deepsup \
    --fc_dim 320
```

* Train ResNet18dilated + PPM_deepsup
```bash
python3 train.py \
    --num_gpus NUM_GPUS --arch_encoder resnet18dilated --arch_decoder ppm_deepsup \
    --fc_dim 512
```

* Train UPerNet101
```bash
python3 train.py \
    --num_gpus NUM_GPUS --arch_encoder resnet101 --arch_decoder upernet \
    --segm_downsampling_rate 4 --padding_constant 32
```

3. See full input arguments via ```python3 train.py -h ```.


## Evaluation
1. Evaluate a trained model on the validation set. ```--id``` is the folder name under ```ckpt``` directory. ```--suffix``` defines which checkpoint to use, for example ```_epoch_20.pth```. Add ```--visualize``` option to output visualizations as shown in teaser.
```bash
python3 eval.py --id MODEL_ID --suffix SUFFIX
```

For example:

* Evaluate MobileNetV2dilated + C1_deepsup
```bash
python3 eval.py \
    --id MODEL_ID --suffix SUFFIX --arch_encoder mobilenetv2dilated --arch_decoder c1_deepsup \
    --fc_dim 320
```

* Evaluate ResNet18dilated + PPM_deepsup
```bash
python3 eval.py \
    --id MODEL_ID --suffix SUFFIX --arch_encoder resnet18dilated --arch_decoder ppm_deepsup \
    --fc_dim 512
```

* Evaluate UPerNet101
```bash
python3 eval.py \
    --id MODEL_ID --suffix SUFFIX --arch_encoder resnet101 --arch_decoder upernet \
    --padding_constant 32
```

***We also provide a multi-GPU evaluation script.*** To run the evaluation code on 8 GPUs, simply add ```--device 0-7```. You can also choose which GPUs to use, for example, ```--device 0,2,4,6```.
```bash
python3 eval_multipro.py --id MODEL_ID --suffix SUFFIX --device DEVICE_ID
```

2. See full input arguments via ```python3 eval.py -h ``` and ```python3 eval_multipro.py -h ```.

## Reference

If you find the code or pre-trained models useful, please cite the following papers:

Semantic Understanding of Scenes through ADE20K Dataset. B. Zhou, H. Zhao, X. Puig, T. Xiao, S. Fidler, A. Barriuso and A. Torralba. International Journal on Computer Vision (IJCV), 2018. (https://arxiv.org/pdf/1608.05442.pdf)

    @article{zhou2018semantic,
      title={Semantic understanding of scenes through the ade20k dataset},
      author={Zhou, Bolei and Zhao, Hang and Puig, Xavier and Xiao, Tete and Fidler, Sanja and Barriuso, Adela and Torralba, Antonio},
      journal={International Journal on Computer Vision},
      year={2018}
    }

Scene Parsing through ADE20K Dataset. B. Zhou, H. Zhao, X. Puig, S. Fidler, A. Barriuso and A. Torralba. Computer Vision and Pattern Recognition (CVPR), 2017. (http://people.csail.mit.edu/bzhou/publication/scene-parse-camera-ready.pdf)

    @inproceedings{zhou2017scene,
        title={Scene Parsing through ADE20K Dataset},
        author={Zhou, Bolei and Zhao, Hang and Puig, Xavier and Fidler, Sanja and Barriuso, Adela and Torralba, Antonio},
        booktitle={Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition},
        year={2017}
    }
    
