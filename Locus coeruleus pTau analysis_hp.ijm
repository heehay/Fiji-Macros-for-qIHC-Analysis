  //batch analysis of following markers in the locus coeruleus (LC):
  //phsophorylated tau (pTau), tyrosine hydroyxlase (TH), neuron (NeuN), DAPI
  
  // each set of images (paired dapi and iba1) should have an unique name - for example the animal ID number and 
  // region name
  
  Dialog.create("Assign Channel ID");
  Dialog.addString("CY5 Image Suffix:", "w4"); //pTau
  Dialog.addString("Red Image Suffix:", "w3"); //TH
  Dialog.addString("Green Image Suffix:", "w2"); //NeuN
  Dialog.addString("Blue Image Suffix:", "w1"); //dapi  
   
      
  cy5Suffix = Dialog.getString() + ".";  
  redSuffix = Dialog.getString() + ".";  
  greenSuffix = Dialog.getString() + ".";
  blueSuffix = Dialog.getString() + ".";
  batchCount();
run("Set Measurements...", "area mean min area_fraction display redirect=None decimal=3"); 

  function batchCount() {
      dir1 = getDirectory("Choose Image Folder to Analyze");
      name = File.getName(dir1);
      dir2 = getDirectory("Select Folder to Save Results");
      list = getFileList(dir1);
      setBatchMode(true);
      //set to false allows us to see the images load as imagej is processing for manual threshold. set to [true] for blind folder batch processing
      n = list.length;
      if ((n%4)!=0)
         exit("The number of files must be a multiple of 4");
      stack = 0;
      first = 0;
      for (i=0; i<n/4; i++) {
          showProgress(i+1, n/4);
          cy5="?";  red="?"; green="?"; blue="?";   
          for (j=first; j<first+4; j++) {
             if (indexOf(list[j], cy5Suffix)!=-1)
                  cy5 = list[j];           
             if (indexOf(list[j], redSuffix)!=-1)
                  red = list[j];
			 if (indexOf(list[j], greenSuffix)!=-1)
                  green = list[j];
             if (indexOf(list[j], blueSuffix)!=-1)
                  blue = list[j];
          }
          
// the macro starts by designating the well area. we crop brain regions of interest from larger 
// images, so our regions are not uniform. since you are working with wells your images should
// be more uniform size. feel free to remove this section, if it is unnecessary. 

//1.calculating the well area for your region of interest          
	open(dir1+blue);
    w1=getTitle();
    run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global"); //20x calibration
    image_width = getWidth();
    image_height = getHeight();
    run("Set Measurements...", "area mean standard modal min perimeter feret's integrated median display redirect=None decimal=3");
    run("Measure");
    changeValues(getResult("Mode", 0), getResult("Mode", 0), 0);
	//run("Threshold...");
	setThreshold(1, 65535, "raw");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	rename("background_area");
	run("Fill Holes");
	b=getTitle();
	run("Create Selection");
	close("Results");
	
	close("Untitled");
	close(w1);
	
	
// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Summary");
	close("Results");

//2. w1 = DAPI     
open(dir1+blue);
w1 = getTitle();
org_width = getWidth();
	org_height = getHeight();
	run("Enhance Contrast", "saturated=0.35");
	setOption("ScaleConversions", true);
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global"); //this scale setting is for 20X images; need to change if magnification is different
	run("Unsharp Mask...", "radius=1 mask=0.60");
	run("Subtract Background...", "rolling=50");
	run("Enhance Contrast", "saturated=0.35");
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");
	run("Remove Outliers...", "radius=4 threshold=50 which=Bright");
	run("8-bit");
	width = (getWidth()*0.20);
	run("Auto Local Threshold", "method=Phansalkar radius=200 parameter_1=0 parameter_2=0 white");
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
	run("Despeckle");
run("Analyze Particles...", "size=5.00-Infinity circularity=0.1-1.00 exclude include show=Masks");	
run("Adjustable Watershed", "tolerance=0.8");
rename("DAPI");	
rename("DAPI+"+ list[j-4]);
w1=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "DAPI+" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.	
close();
run("Select None");
roiManager("reset");



 //3. w2 = NeuN
open(dir1+green);
w2 = getTitle();
selectImage("background_area");
run("Create Selection");

selectImage(w2);
 	image_width = getWidth();
    image_height = getHeight();
	width = (getWidth()*0.05);
	//	print(width);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	changeValues(0, 0, getResult("Mean",0));
	close("Results");
	run("Subtract Background...", "rolling=50");
    run("Restore Selection");
	run("Measure");
	run("Select None");
	avg = getResult("Mean", 0);
	run("Subtract...", "value=avg");	
	run("8-bit");
	setAutoThreshold("Li dark");
	run("Convert to Mask");
	run("Despeckle");
	run("Adjustable Watershed", "tolerance=0.5");
	run("Analyze Particles...", "size=15-infinity show=Masks exclude");

	rename("NeuN");	
	rename("NeuN+"+ list[j-4]);
	w2 = getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "NeuN+" + list[j-4] + ".jpg");
	close();
run("Select None");
roiManager("reset");


//4. w3 = TH
open(dir1+red);
w3 = getTitle();

selectImage("background_area");
run("Create Selection");

selectImage(w3);
 	

	image_width = getWidth();
    image_height = getHeight();

	width = (getWidth()*0.05);
	//	print(width);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	changeValues(0, 0, getResult("Mean",0));
	close("Results");

	run("Subtract Background...", "rolling=50");

    run("Restore Selection");
	run("Measure");
	run("Select None");
	avg = getResult("Mean", 0);
	run("Subtract...", "value=avg");	

	
	run("8-bit");
	setAutoThreshold("IsoData dark");
	run("Convert to Mask");
	close("Results");
	run("Set Measurements...", "area mean standard min center perimeter shape integrated median skewness kurtosis area_fraction display redirect=None decimal=3");
	rename("TH");
	close("w3");
	selectImage("TH");

	
run("Analyze Particles...", "size=15-Infinity exclude add");
	run("Despeckle");
	run("Despeckle");
	rename("TH");	
	rename("TH+"+ list[j-4]);
	w3 = getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "TH+" + list[j-4] + ".jpg"); 
	close();


run("Select None");
roiManager("reset");

//5. w4 = pTau
open(dir1+cy5);
w4 = getTitle();

selectImage("background_area");
run("Create Selection");

selectImage(w4);
 	image_width = getWidth();
    image_height = getHeight();
	width = (getWidth()*0.05);
	//	print(width);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	changeValues(0, 0, getResult("Mean",0));
	close("Results");
	run("Subtract Background...", "rolling=50");
    run("Restore Selection");
	run("Measure");
	run("Select None");
	avg = getResult("Mean", 0);
	run("Subtract...", "value=avg");	
	run("8-bit");
	setAutoThreshold("IJ_IsoData dark"); 
	run("Convert to Mask");
	run("Despeckle");
	run("Despeckle");   

	rename("pTau");	
	rename("pTau+"+ list[j-4]);
	w4 = getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "pTau+" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.	
	close();

	run("Select None");
	roiManager("reset");
///////////////////////////////////////////////////////////////////////////////
//6. Identifying TH-positive NeuN
   run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
   selectImage(w2); //w2=NeuN mask
  run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w3); //TH mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all no-edge map2+synaptophysin ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs - no-edge map2+synaptophysin ROIs
newImage("Untitled", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("TH_NeuN"); 
rename("TH_NeuN+"+ list[j-4]);
w5 = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "TH_NeuN+" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.	
close();
close("Untitled");

	



run("Select None");
roiManager("reset");


//7. Identifying TH-positive NeuN with ptau
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w5); //w5=TH_NeuN mask
  run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w4); //ptau mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs
newImage("ptau_TH_NeuN", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("ptau_TH_NeuN"); 
rename("ptau_TH_NeuN+"+ list[j-4]);
w6 = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "ptau_TH_NeuN+" + list[j-4] + ".jpg"); 
close();



run("Select None");
roiManager("reset");



//8. Identifying NeuN with ptau
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w2); //w2=NeuN mask
 run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w4); //ptau mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs
newImage("ptau_NeuN", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("ptau_NeuN"); 
rename("ptau_NeuN+"+ list[j-4]);
w7 = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "ptau_NeuN+" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.	
close();


//9. Segmenting all masks with DAPI to get a more accurate count
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w1); //w1=DAPI mask
 run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w2); //NeuN mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with  ROIs
newImage("Untitled", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("NeuN_final"); 
rename("final_NeuN+"+ list[j-4]);
final_NeuN = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "final_NeuN+" + list[j-4] + ".jpg"); 
close();
close("Untitled");



roiManager("reset");
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w1); //w1=DAPI mask
run("Select None");
 run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w3); //TH mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs 
newImage("Untitled", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("final_TH+"+ list[j-4]);
final_TH = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "final_TH+" + list[j-4] + ".jpg"); 
close();
close("Untitled");



roiManager("reset");
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w1); //w1=DAPI mask
run("Select None");
 run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w4); //pTau mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs 
newImage("Untitled", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("final_ptau+"+ list[j-4]);
final_ptau = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "final_ptau+" + list[j-4] + ".jpg"); 
close();
close("Untitled");



roiManager("reset");
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w1); //w1=DAPI mask
run("Select None");
 run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w5); //TH-NeuN mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs
newImage("Untitled", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("final_TH_NeuN+"+ list[j-4]);
final_TH_NeuN = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "final_TH_NeuN+" + list[j-4] + ".jpg");
close();
close("Untitled");


roiManager("reset");
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w1); //w1=DAPI mask
run("Select None");
 run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w6); //ptau-TH-NeuN mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs 
newImage("Untitled", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("final_ptau_TH_NeuN+"+ list[j-4]);
final_ptau_TH_NeuN = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "final_ptau_TH_NeuN+" + list[j-4] + ".jpg"); 
close();
close("Untitled");


roiManager("reset");
run("Set Measurements...", "area mean standard modal min area_fraction perimeter feret's integrated median display redirect=None decimal=3");
selectImage(w1); //w1=DAPI mask
run("Select None");
 run("Analyze Particles...", "size=0-Infinity exclude add");

  selectImage(w7); //ptau-NeuN mask
	run("Select None");
	close("Results");
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

/// look at all the measurements. create a new array that is populated by only those rois that meet the below criteria. and then delete out all the rois contained within the new array. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("%Area", l)<10) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////
// selecting and combining all ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");
    image_width = getWidth();
    image_height = getHeight();

// create new overlay image with ROIs 
newImage("Untitled", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("final_ptau_NeuN+"+ list[j-4]);
final_ptau_NeuN = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "final_ptau_NeuN+" + list[j-4] + ".jpg"); 
close();
close("Untitled");

	
//opening final masks to record results
selectImage(w4); // ptau
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w2); //NeuN
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(final_NeuN); //NeuN
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w3); //TH percent area
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(final_TH); //TH count
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w5); // 
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(final_TH_NeuN); //TH_NeuN
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w6); //TH percent area
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(final_ptau_TH_NeuN); //ptau_TH_NeuN
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(w7); //TH percent area
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(final_ptau_NeuN); //ptau_NeuN
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results

selectImage(b); 
rename("background_area+" + list[j-4]);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); // measurement results


// save results	
	selectWindow("Summary");
	saveAs("results", dir2 + list[j-4] + ".txt");
	//roiManager("Delete");
	close("Results");
	close("Summary");
	close("Threshold");  
	roiManager("reset");
	close("ROI Manager");
	close("Untitled");
	close("Results");
    close("*");
    close("*.txt");
	run("Close All");
	showProgress(i, list.length);
          first += 4;
      }}


setBatchMode(false);
waitForUser("complete, Click Okay");

