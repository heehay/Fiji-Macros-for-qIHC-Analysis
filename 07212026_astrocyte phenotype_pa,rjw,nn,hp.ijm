//Astrocyte morphology analysis

  // assign dapi - _w1, gfap - _w2, trem2 - _w2, vimentin - _w3 at the end of the image file name
  // each set of images (paired dapi and gfap) should have an unique name - for example the animal ID number and 
  // region name.

  Dialog.create("Assign Channel ID");
  Dialog.addString("CY5 Image Suffix:", "w4"); //gfap
  Dialog.addString("Green Image Suffix:", "w3"); //vimentin
  Dialog.addString("Red Image Suffix:", "w2"); //trem2
  Dialog.addString("Blue Image Suffix:", "w1"); //dapi  
  //Dialog.show();//delete this line to hide the dialog box if you always have the same image suffix per color
  cy5Suffix = Dialog.getString() + ".";
  greenSuffix = Dialog.getString() + ".";
  redSuffix = Dialog.getString() + ".";
  blueSuffix = Dialog.getString() + ".";
  batchCount();

  function batchCount() {
      dir1 = getDirectory("Choose Image Folder to Analyze");
      name = File.getName(dir1);
      dir2 = getDirectory("Select Folder to Save Results");
      list = getFileList(dir1);
      setBatchMode(false);
      //set to false allows us to see the images load as imagej is processing for manual threshold. set to [true] for blind folder batch processing
      n = list.length;
      if ((n%4)!=0)
         exit("The number of files must be a multiple of 4");
      stack = 0;
      first = 0;
      for (i=0; i<n/4; i++) {
          showProgress(i+1, n/4);
          cy5="?";   green="?"; red="?"; blue="?";   
          for (j=first; j<first+4; j++) {
             if (indexOf(list[j], cy5Suffix)!=-1)
                  cy5 = list[j];           
             if (indexOf(list[j], greenSuffix)!=-1)
                  green = list[j];
             if (indexOf(list[j], redSuffix)!=-1)
                  red = list[j];
             if (indexOf(list[j], blueSuffix)!=-1)
                  blue = list[j];
          }


// the macro starts by designating the well area. we crop brain regions of interest from larger 
// images, so our regions are not uniform. since you are working with wells your images should
// be more uniform size. feel free to remove this section, if it is unnecessary. 
	run("Set Measurements...", "area mean standard modal min center perimeter shape integrated median area_fraction display redirect=None decimal=3");
//calculating the well area for your region of interest          
    open(dir1+blue);
    w1=getTitle();
    run("Set Measurements...", "area mean standard modal min center perimeter shape integrated median area_fraction display redirect=None decimal=3");
    run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");
    image_width = getWidth();
    image_height = getHeight();
   run("Measure");
   	changeValues(getResult("Mode", 0), getResult("Mode", 0), 0);
    setThreshold(1, 65535);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Fill Holes");
	run("Create Selection");

	newImage("Untitled", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	rename("background_area");
	background_area = getTitle();
	
	newImage("Untitled", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Draw", "slice");
	run("Select None");
	run("Invert");
	rename("just_edge");
	run("Invert");
	setThreshold(1, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	
	close("Untitled");
	close(w1);
	
	// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");


	
// identifying gfap+ objects. performs a couple of background subtraction steps, which may not be needed for 
// your images.
	open(dir1+cy5);
	run("Select None");
	run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");
	w4 = getTitle();
	close("Results");
	run("Set Measurements...", "area mean standard modal min center perimeter shape integrated median area_fraction display redirect=None decimal=3");
	
	//Correcting background
	selectImage("background_area");
	run("Create Selection");
	selectImage(w4);
	image_width = getWidth();
    image_height = getHeight();

	width = (getWidth()*0.05);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	changeValues(0, 0, getResult("Mean",0));
	close("Results");

	run("Subtract Background...", "rolling=400");

    run("Restore Selection");
	run("Measure");
	run("Select None");
	avg = getResult("Mean", 0);
	run("Subtract...", "value=avg");	

	
	run("8-bit");
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
	rename("orginal_gfap_mask");
	selectWindow("orginal_gfap_mask");
//////////////////////////////////////This part is to exclude non-gfap background staining with size filteration////////////////
	run("Analyze Particles...", "size=50-Infinity show=Masks");
	rename("large_chunk");
	
	imageCalculator("Subtract create", "orginal_gfap_mask","large_chunk");
	rename("small_chunk");
	
	selectWindow("large_chunk");
	run("Dilate");
	run("Analyze Particles...", "size=30-500 show=Masks");
	rename("large_filtered");
	selectWindow("large_filtered");
	run("Erode");
	
	selectWindow("large_filtered");
	run("Analyze Particles...", "circularity=0-0.6 show=Masks");
	rename("irregular_large_chunk");

	
	imageCalculator("Add create", "irregular_large_chunk","small_chunk");
////////////////////////////////////////////////End of size filteration part ////////////////////////////
	rename("all_gfap"); 
	selectWindow("all_gfap");
	rename("all_gfap_area+"+ list[j-4]); 
	all_gfap=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "all_gfap+" + list[j-4] + ".jpg");
	close();
	close("Results");
	
		// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");




///2. identifying DAPI objects
	open(dir1+blue);
	w1=getTitle();
	org_width = getWidth();
	org_height = getHeight();
    
    
	//run("Brightness/Contrast...");
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
	run("Fill Holes");
	run("Fill Holes");
	rename("org.dapi.mask");
	run("Analyze Particles...", "size=15.00-Infinity circularity=0.1-1.00 exclude include show=Masks");	
	run("Convert to Mask");
	rename("DAPI");
	close("org.dapi.mask");
	
// try to run adjustable watershed. 
// will first pull out only those objects deemed large enough to be clustered nuclei.
	selectWindow("DAPI");
	run("Analyze Particles...", "size=150-Infinity show=Masks");
	selectWindow("Mask of DAPI");
	run("Adjustable Watershed", "tolerance=0.5");
	run("Analyze Particles...", "size=15-Infinity show=Masks");
	rename("watershed_clustered_nuclei_mask");
	close("Mask of DAPI");
	
	selectWindow("DAPI");
	run("Analyze Particles...", "size=0-149 show=Masks");
	rename("small_nuclei");
	selectWindow("small_nuclei");
	run("Analyze Particles...", "circularity=0.25-0.59 show=Masks");
	rename("irregular_nuclei");
	selectWindow("small_nuclei");
	run("Analyze Particles...", "circularity=0.60-1.00 show=Masks");	
	rename("small_circular_nuclei");	
	selectWindow("small_circular_nuclei");
	run("Adjustable Watershed", "tolerance=1");
	run("Analyze Particles...", "size=15-Infinity show=Masks");
	rename("watershed_small_nuclei");
	selectWindow("irregular_nuclei");
	run("Adjustable Watershed", "tolerance=1.5");
	
	imageCalculator("OR create", "watershed_small_nuclei","irregular_nuclei");
	rename("watershed_small_nuclei_2");

	imageCalculator("OR create", "watershed_clustered_nuclei_mask","watershed_small_nuclei_2");
	selectWindow("Result of watershed_clustered_nuclei_mask");
	rename("dapi_watershed");


	w1=getTitle();
	
		if (roiManager("count") > 0) {
		roiManager("delete");
		}
			if (roiManager("count") > 0) {
		roiManager("delete");
		}
		
		
// filter out dapi objects that do not sufficiently colocalize with gfap		
	selectImage("dapi_watershed");
	run("Select None");
	run("Analyze Particles...", "size=0-Infinity show=Nothing add");
	selectImage(all_gfap);
	run("Select None");
	run("Remove Overlay");
	
	
//// new MUCH faster array strategy for looping	through potential rois. create an array of all potential rois. measure all the rois. 
	
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
		      if (getResult("%Area", l)<20) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");


if (roiManager("count") > 0) {
// selecting all rois	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Combine");
	}


	image_width = getWidth();
    image_height = getHeight();

// creating a new mask of just dapi objects > 10um2 and your given percentage overlap with gfap+ objects
	newImage("gfap_nuclei", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("gfap_nuclei");
	selectWindow("Mask");
	rename("gfap_nuclei") ;
}
else {
	newImage("gfap_nuclei", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[gfap_nuclei]");
	selectWindow("gfap_nuclei");
}
if (isOpen("gfap_nuclei")) {
}
else {
	newImage("gfap_nuclei", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[gfap_nuclei]");
	selectWindow("gfap_nuclei");
}

selectWindow("gfap_nuclei");
rename("gfap_nuclei+"+ list[j-4]); 
gfap_nuclei=getTitle();

	
	// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");


// Getting DAPI-positive glia marker
selectImage(all_gfap);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity show=Nothing add");
selectImage(gfap_nuclei);
run("Select None");
run("Remove Overlay");

	
//// new MUCH faster array strategy for looping	through potential rois. create an array of all potential rois. measure all the rois. 
	
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
		      if (getResult("%Area", l)==0) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");


if (roiManager("count") > 0) {
// selecting all rois	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Combine");
	}



	image_width = getWidth();
    image_height = getHeight();

// creating a new mask of just dapi objects > 10um2 and your given percentage overlap with gfap+ objects
	newImage("final_gfap", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("final_gfap");
	selectWindow("Mask");
	rename("final_gfap_count") ;
}
else {
	newImage("final_gfap_count", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[final_gfap_count]");
	selectWindow("final_gfap_count");
}
if (isOpen("final_gfap_count")) {
}
else {
	newImage("final_gfap_count", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[final_gfap_count]");
	selectWindow("final_gfap_count");
}


selectWindow("final_gfap_count");
rename("final_gfap_count+"+ list[j-4]); 
final_gfap_count=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "final_gfap_count+" + list[j-4] + ".jpg");
close();
	
	// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");


//// identifying trem2+ objects. adjust the threshold with setAutoThreshold(*whatever algorithm*)
open(dir1+red);
run("Select None");
w2 = getTitle();
close("Results");
 run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");
 
run("Set Measurements...", "area mean standard modal min center perimeter shape integrated median area_fraction display redirect=None decimal=3");

selectImage("background_area");
run("Create Selection");
selectImage(w2);
run("Restore Selection");
run("Measure");

image_mean = getResult("Mean", 0);
lower_threshold = getResult("Mean", 0) + getResult("StdDev", 0);

print(image_mean);
print(lower_threshold);

close("Results");

selectImage(w2);
run("Select None");
run("Select All");
run("Measure");
run("Enhance Contrast", "saturated=0.35");
setOption("ScaleConversions", true);
run("Select None");

// change cropped out intensity to the mean intensity of your cropped area
// this helps background subtraction without producing edge effects
changeValues(getResult("Mode", 0), getResult("Mode", 0), image_mean);

run("8-bit");
close("Results");

run("Subtract Background...", "rolling=100");
setAutoThreshold("MaxEntropy dark");
run("Create Mask");
run("Despeckle");
run("Despeckle");
//run("Analyze Particles...", "size=0-Infinity show=Masks");
rename("trem2_labeling");
rename("trem2_labeling+"+ list[j-4]); 
trem2_labeling=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "trem2_labeling+" + list[j-4] + ".jpg");
close();

close("Results");
close("Summary");
if (roiManager("count") > 0) {
    roiManager("delete");
}



/// getting area colocalization (trem2-gfap)
	imageCalculator("AND create", trem2_labeling,all_gfap);
	rename("trem2_gfap_area+"+ list[j-4]); 
	trem2_gfap_area=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "trem2_gfap_area+" + list[j-4] + ".jpg");
	close();

close("Results");
close("Summary");
if (roiManager("count") > 0) {
    roiManager("delete");
}


// Getting count colocalized (trem2-gfap)
selectImage(final_gfap_count);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity show=Nothing add");
selectImage(trem2_labeling);
run("Select None");
run("Remove Overlay");

	
//// new MUCH faster array strategy for looping	through potential rois. create an array of all potential rois. measure all the rois. 
	
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
		      if (getResult("%Area", l)==0) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");


if (roiManager("count") > 0) {
// selecting all rois	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Combine");
	}



	image_width = getWidth();
    image_height = getHeight();

// creating a new mask of just dapi objects > 10um2 and your given percentage overlap with gfap+ objects
	newImage("final_gfap", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("final_gfap");
	selectWindow("Mask");
	rename("trem2_gfap_count") ;
	
}
else {
	newImage("trem2_gfap_count", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[trem2_gfap_count]");
	selectWindow("trem2_gfap_count");
}
if (isOpen("trem2_gfap_count")) {
}
else {
	newImage("trem2_gfap_count", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[trem2_gfap_count]");
	selectWindow("trem2_gfap_count");
}

selectWindow("trem2_gfap_count");
rename("trem2_gfap_count+"+ list[j-4]); 
trem2_gfap_count=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "trem2_gfap_count+" + list[j-4] + ".jpg");
close();

close("Results");
close("Summary");
if (roiManager("count") > 0) {
    roiManager("delete");
}


//// identifying vimentin+ objects. adjust the threshold with setAutoThreshold(*whatever algorithm*)
open(dir1+green);
run("Select None");
 run("Set Scale...", "distance=2.9851 known=1 pixel=1 unit=µm global");
w3 = getTitle();
	close("Results");
	run("Set Measurements...", "area mean standard modal min center perimeter shape integrated median area_fraction display redirect=None decimal=3");
	run("Measure");
	run("Enhance Contrast", "saturated=0.35");
	setOption("ScaleConversions", true);
	changeValues(getResult("Mode", 0), getResult("Mode", 0), 0);
	close("Results");

	selectImage("background_area");
	run("Create Selection");
	selectWindow(w3);
	run("Remove Outliers...", "radius=2 threshold=5 which=Bright");
	run("Restore Selection");
	run("Measure");
	changeValues(30000, 65535, getResult("Mean", 0));
	run("Measure");
	selectWindow(w3);
	run("Select None");
	changeValues(0, getResult("Mean", 1), getResult("Mean", 1));

run("Subtract Background...", "rolling=300");
setAutoThreshold("Moments dark");
run("Create Mask");
rename("orginal_vimentin_mask");
	selectWindow("orginal_vimentin_mask");
//////////////////////////////////////This part is to exclude non-vimentin background staining with size filteration////////////////
	run("Analyze Particles...", "size=50-Infinity show=Masks");
	rename("v_large_chunk");
	
	imageCalculator("Subtract create", "orginal_vimentin_mask","v_large_chunk");
	rename("v_small_chunk");
	
	selectWindow("v_large_chunk");
	run("Dilate");
	run("Analyze Particles...", "size=30-1200 show=Masks");
	rename("v_large_filtered");
	selectWindow("v_large_filtered");
	run("Erode");
	
	selectWindow("v_large_filtered");
	run("Analyze Particles...", "circularity=0-0.6 show=Masks");
	rename("v_irregular_large_chunk");

	
	imageCalculator("Add create", "v_irregular_large_chunk","v_small_chunk");
////////////////////////////////////////////////End of size filteration part ////////////////////////////

rename("vimentin+"+ list[j-4]); 
vimentin=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "vimentin+" + list[j-4] + ".jpg");
close();

close("Results");
close("Summary");
if (roiManager("count") > 0) {
    roiManager("delete");
}



/// Getting count colocalized (vimentin-gfap)
	imageCalculator("AND create", vimentin,all_gfap);
	rename("vimentin_gfap_area+"+ list[j-4]); 
	vimentin_gfap_area=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "vimentin_gfap_area+" + list[j-4] + ".jpg");
	close();

close("Results");
close("Summary");
if (roiManager("count") > 0) {
    roiManager("delete");
}

// Getting count colocalized (vimentin-gfap)
selectImage(final_gfap_count);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity show=Nothing add");
selectImage(vimentin);
run("Select None");
run("Remove Overlay");

	
//// new MUCH faster array strategy for looping	through potential rois. create an array of all potential rois. measure all the rois. 
	
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
		      if (getResult("%Area", l)==0) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");


if (roiManager("count") > 0) {
// selecting all rois	
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Combine");
	}



	image_width = getWidth();
    image_height = getHeight();

// creating a new mask of just dapi objects > 10um2 and your given percentage overlap with gfap+ objects
	newImage("final_gfap", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("final_gfap");
	selectWindow("Mask");
	rename("vimentin_gfap_count") ;
	
}
else {
	newImage("vimentin_gfap_count", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[vimentin_gfap_count]");
	selectWindow("vimentin_gfap_count");
}
if (isOpen("vimentin_gfap_count")) {
}
else {
	newImage("vimentin_gfap_count", "8-bit black", image_width, image_height, 1);
	run("Duplicate...", "title=[vimentin_gfap_count]");
	selectWindow("vimentin_gfap_count");
}

selectWindow("vimentin_gfap_count");
rename("vimentin_gfap_count+"+ list[j-4]); 
vimentin_gfap_count=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "vimentin_gfap_count+" + list[j-4] + ".jpg");
close();

close("Results");
close("Summary");
if (roiManager("count") > 0) {
    roiManager("delete");
}



//// identifying triple colocalization (vimentin+ trem2+ gfap)

/// area of colocalized
	imageCalculator("AND create", vimentin_gfap_area,trem2_gfap_area);
	rename("triple_area+"+ list[j-4]); 
	triple_area=getTitle();
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "triple_area+" + list[j-4] + ".jpg");
	close();


/// count of colocalized
	imageCalculator("AND create", vimentin_gfap_count,trem2_gfap_count);
	rename("triple_count+"+ list[j-4]); 
	triple_count=getTitle();
	run("Duplicate...", " ");
	run("Duplicate...", " ");
	saveAs("jpg", dir2+ "triple_count+" + list[j-4] + ".jpg");
	close();




//get cell counts

run("Set Measurements...", "area mean min center perimeter bounding shape feret's area_fraction display redirect=None decimal=3");
close("Summary");

selectWindow(background_area);
rename("background+" + list[j-4]);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(all_gfap);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(final_gfap_count);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(trem2_labeling);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(trem2_gfap_area);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(trem2_gfap_count);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(vimentin_gfap_area);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(vimentin_gfap_count);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(triple_area);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");

selectWindow(triple_count);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");


selectWindow("Summary");
saveAs("results", dir2+"Astrocyte_phenotype+" + list[j-4] + ".txt");

	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");
	
	
	
/// Now do the skeletonize to get the other morphology measurements. 

//first all gfap
selectWindow(final_gfap_count);
run("Select None");
run("Remove Overlay");

// Check whether mask has any positive signal
getStatistics(area, mean, min, max);

if (max > 0) {
	
	selectWindow(final_gfap_count);
    run("Skeletonize");
    run("Analyze Skeleton (2D/3D)", "prune=none calculate");


} else {
    // If mask is empty, create a blank image so the workflow can continue
    image_width = getWidth();
    image_height = getHeight();

    newImage("Skeleton of " + final_gfap_count, "8-bit black", image_width, image_height, 1);

    // Add zeros to Results table
    row = nResults;
    setResult("Branches", row, 0);
    setResult("Junctions", row, 0);
    setResult("End-point voxels", row, 0);
    setResult("Junction voxels", row, 0);
    setResult("Slab voxels", row, 0);
    setResult("Average Branch Length", row, 0);
    setResult("Triple points", row, 0);
    setResult("Quadruple points", row, 0);
    setResult("Maximum Branch Length", row, 0);

    updateResults();
}


// Save skeleton results
selectWindow("Results");
saveAs("results", dir2+"gfap_skeleton+"+list[j-4]+".csv");
close("Results");
selectWindow(final_gfap_count);
rename("gfap_skeleton+"+ list[j-4]); 
run("Duplicate...", " ");
saveAs("jpg", dir2+ "gfap_skeleton+" + list[j-4] + ".jpg");
close();


	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");
	

//trem2-gfap
selectWindow(trem2_gfap_count);
run("Select None");
run("Remove Overlay");

// Check whether mask has any positive signal
getStatistics(area, mean, min, max);

if (max > 0) {
	
	selectWindow(trem2_gfap_count);
    run("Skeletonize");
    run("Analyze Skeleton (2D/3D)", "prune=none calculate");


} else {
    // If mask is empty, create a blank image so the workflow can continue
    image_width = getWidth();
    image_height = getHeight();

    newImage("Skeleton of " + trem2_gfap_count, "8-bit black", image_width, image_height, 1);

    // Add zeros to Results table
    row = nResults;
    setResult("Branches", row, 0);
    setResult("Junctions", row, 0);
    setResult("End-point voxels", row, 0);
    setResult("Junction voxels", row, 0);
    setResult("Slab voxels", row, 0);
    setResult("Average Branch Length", row, 0);
    setResult("Triple points", row, 0);
    setResult("Quadruple points", row, 0);
    setResult("Maximum Branch Length", row, 0);

    updateResults();
}

// Save skeleton results
selectWindow("Results");
saveAs("results", dir2+"trem2_gfap_skeleton+"+list[j-4]+".csv");
close("Results");
selectWindow(trem2_gfap_count);
rename("trem2_gfap_skeleton+"+ list[j-4]); 
run("Duplicate...", " ");
saveAs("jpg", dir2+ "trem2_gfap_skeleton+" + list[j-4] + ".jpg");
close();
close("Longest shortest paths");
close("Tagged skeleton");

	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");
	

//vimentin-gfap
selectWindow(vimentin_gfap_count);
run("Select None");
run("Remove Overlay");

// Check whether mask has any positive signal
getStatistics(area, mean, min, max);

if (max > 0) {
	selectWindow(vimentin_gfap_count);
    run("Skeletonize");
    run("Analyze Skeleton (2D/3D)", "prune=none calculate");

    

} else {
    // If mask is empty, create a blank image so the workflow can continue
    image_width = getWidth();
    image_height = getHeight();

    newImage("Skeleton of " + vimentin_gfap_count, "8-bit black", image_width, image_height, 1);

    // Add zeros to Results table
    row = nResults;
    setResult("Branches", row, 0);
    setResult("Junctions", row, 0);
    setResult("End-point voxels", row, 0);
    setResult("Junction voxels", row, 0);
    setResult("Slab voxels", row, 0);
    setResult("Average Branch Length", row, 0);
    setResult("Triple points", row, 0);
    setResult("Quadruple points", row, 0);
    setResult("Maximum Branch Length", row, 0);

    updateResults();
}


// Save skeleton results
selectWindow("Results");
saveAs("results", dir2+"vimentin_gfap_skeleton+"+list[j-4]+".csv");
close("Results");
selectWindow(vimentin_gfap_count);
rename("vimentin_gfap_skeleton+"+ list[j-4]); 
run("Duplicate...", " ");
saveAs("jpg", dir2+ "vimentin_gfap_skeleton+" + list[j-4] + ".jpg");
close();


	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Results");
	close("Summary");


// close all of your working images and repeat on the next set of images. 	
			
	run("Remove Overlay");
	close("Results");
	close("Summary");
	close("Threshold");  
	close("ROI Manager");
    close("*");
    close("*.txt");
	showProgress(i, list.length);
          first += 4;
      }
}

Dialog.create("DONE");
Dialog.show();
exit;

