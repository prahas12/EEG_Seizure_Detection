# Literature Review: EEG-Based Seizure Detection

## Overview
This document reviews key literature in the domain of EEG-based patient-independent seizure detection, focusing on the CHB-MIT dataset.

## Academic & Technical Sources

### 1. Shoeb, A. H. (2009). Application of Machine Learning to Epileptic Seizure Onset Detection and Treatment.
*   **Contribution:** The original MIT PhD thesis that introduced the CHB-MIT database. It describes a patient-specific SVM model using temporal and spectral features (spectral energy in 0.5-25Hz bands).
*   **Adopting:** The definition of seizure onsets and offsets, and the use of filter banks for extracting spectral energy features.
*   **Improving:** Moving from patient-specific SVMs to a generalized, patient-independent classification framework to avoid the need for prior seizure data from new patients.

### 2. Truong, N. D., et al. (2018). Convolutional neural networks for seizure prediction using intracranial and scalp electroencephalogram. *Neural Networks*.
*   **Contribution:** Demonstrates the use of STFT (Short-Time Fourier Transform) spectrograms as 2D inputs for CNNs. Highlights the challenges of class imbalance and data leakage.
*   **Adopting:** The concept of using non-overlapping windows for training and extracting time-frequency representations (spectrograms).
*   **Improving:** We implement an interpretable classical machine learning pipeline with extracted features rather than black-box CNNs to ensure explainability in a clinical context.

### 3. Zabihi, M., et al. (2015). Patient-specific seizure detection using non-linear dynamics and classical features. *IEEE EMBS*.
*   **Contribution:** Explores non-linear features (entropy, phase-space) combined with conventional time-frequency features (wavelets) for seizure detection.
*   **Adopting:** The inclusion of non-linear characteristics (e.g., spectral entropy, variance) in addition to basic band power.
*   **Improving:** Expanding evaluation to patient-independent (leave-one-patient-out) cross-validation, which wasn't the main focus of this patient-specific study.

### 4. Boonyakitanont, P., et al. (2020). A review of feature extraction and performance evaluation in epileptic seizure detection using EEG. *Telematics and Informatics*.
*   **Contribution:** A comprehensive review indicating that wavelet transforms (DWT/CWT) consistently yield robust features for EEG. Recommends strict patient-level separation.
*   **Adopting:** Discrete Wavelet Transform (DWT) feature extraction and the rigorous patient-independent evaluation methodology (LOPO-CV).
*   **Improving:** Combining wavelet features with temporal smoothing (post-processing) to reduce isolated false alarms, forming a complete end-to-end detection pipeline.

### 5. Goldberger, A. L., et al. (2000). PhysioBank, PhysioToolkit, and PhysioNet. *Circulation*.
*   **Contribution:** The foundational paper for the PhysioNet repository, which hosts the CHB-MIT dataset.
*   **Adopting:** The standards for open access biomedical data and the format (EDF) used for EEG signal storage.

## Open-Source Repositories

### 1. Seizure-Detection-Prediction (JonathanCauchi)
*   **Contribution:** MATLAB-based processing of the CHB-MIT dataset for detection and prediction.
*   **Adopting:** The basic MATLAB preprocessing workflow for filtering EDF data.
*   **Improving:** Implementing more robust artifact handling and explicitly avoiding data leakage in the evaluation phase.

### 2. Epileptic-Seizure-Detection-Based-on-EEG-Signals (RezaSaadatyar)
*   **Contribution:** MATLAB code using wavelet analysis and SVM/KNN classifiers.
*   **Adopting:** Extracting statistical features (variance, RMS, etc.) from DWT coefficients.
*   **Improving:** Wrapping the workflow in a modern object-oriented MATLAB architecture and providing a professional GUI.

### 3. eeg-signal-processing-matlab (miguel-martindominguez)
*   **Contribution:** Demonstrates frequency-band analysis (Delta, Theta, Alpha, Beta, Gamma) in MATLAB.
*   **Adopting:** The specific cutoff frequencies for the five standard EEG frequency bands.
*   **Improving:** Integrating band power features with wavelet features and passing them to an ensemble classifier with temporal post-processing.
