# Fiji-Macros-for-in vivo brain quantitative immunohistochemistry analysis
Uploaded files are Fiji macros customized to to batch analyze in vivo rat immunohistochemistry brain images for quantitative analysis.
All thresholding algorithms used in the macros are available on Fiji software ImageJ version 1.54f, National Institutes of Health; Bethesda, MD, USA).
**All thresholding algorithms and background correction methods need to be optimized for each biomarker based on the quality of IHC, resolution of images, and batch-to-batch variations (if applicable). 

**Additional adjustable watershed plugin is necessary to run the macros.
    Adjustable watershed plugin from:
        media/adjustable-watershed/Adjustable_Watershed.java 
        https://imagej.net/plugins/adjustable-watershed/adjustable-watershed

- 06082026_microglia_phenotype: Analyzes microglial cell count, percent area, and morphology (branches mean, junctions mean, average size, max length mean, average length mean, circularity, solidity, and perimeter). 
This code has been customized for IHC co-stained for: IBA1, CD68, and CD16.

- 06082026_tmem phenotype: Analyzes microglial cell count, percent area, and morphology (branches mean, junctions mean, average size, max length mean, average length mean, circularity, solidity, and perimeter). 
This code has been customized for IHC stained for: TMEM119

- 07212026_astrocyte phenotype: Analyzes astrocytic cell count, percent area, and morphology (branches mean, junctions mean, average size, max length mean, average length mean, circularity, solidity, and perimeter). 
This code has been customized for IHC co-stained for: GFAP, vimentin, and TREM2.

- 08192025_synapses_synaptophysin_sd95_map2: Analyzes immunopositive percent area of  synaptic densities by co-localizing map2, psd95, and synaptophysin.

- Locus coeruleus pTau analysis: Analyzes cell count and percent area of pTau, NeuN, and TH in the locus coeruleus (LC) brain region. 

- Tyrosine hydroxylase analysis_CA1: Analyzes immunopositive percent area of tyrosine hydroxylase staining.
This code has been customized for CA1 hippocampal subregion.

- Tyrosine hydroxylase analysis_CA3: Analyzes immunopositive percent area of tyrosine hydroxylase staining.
This code has been customized for CA3 hippocampal subregion.

- Tyrosine hydroxylase analysis_DG: Analyzes immunopositive percent area of tyrosine hydroxylase staining.
This code has been customized for DG hippocampal subregion.

- Tyrosine hydroxylase analysis_EC: Analyzes immunopositive percent area of tyrosine hydroxylase staining.
This code has been customized for entorhinal cortex (EC).

