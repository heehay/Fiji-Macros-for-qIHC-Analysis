//synapses analysis

  // assign each dapi - _w1, psd95 - _w4, map2 - _w2, synaptophysin - _w3 at the end of the image file name
  // each set of images (paired) should have an unique name - for example the animal ID number and 
  // region name. 

//Following markers are analyzed for synaptic density analysis:  
  Dialog.create("Assign Channel ID");
  Dialog.addString("CY5 Image Suffix:", "w4"); //PSD95
  Dialog.addString("Green Image Suffix:", "w3"); //synaptophysin
  Dialog.addString("Red Image Suffix:", "w2"); //MAP2
  Dialog.addString("Blue Image Suffix:", "w1"); //dapi  
   
  
  //Dialog.show();//delete this line to hide the dialog box if you always have the same image suffix per color
    
  cy5Suffix = Dialog.getString() + ".";
  greenSuffix = Dialog.getString() + ".";
  redSuffix = Dialog.getString() + ".";
  blueSuffix = Dialog.getString() + ".";
  
  function sort(list) {
    for (i = 0; i < list.length - 1; i++) {
        for (j = i + 1; j < list.length; j++) {
            if (list[j] < list[i]) {
                temp = list[i];
                list[i] = list[j];
                list[j] = temp;
            }
        }
    }
    return list;
}

  batchCount();
run("Set Measurements...", "area mean min area_fraction display redirect=None decimal=3"); 

  function batchCount() {
      dir1 = getDirectory("Choose Image Folder to Analyze");
      name = File.getName(dir1);
      list = getFileList(dir1);
      
      dir2 = getDirectory("Select Folder to Save Results");
      list = getFileList(dir1);
      list = sort(list);
      setBatchMode(false);
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
	
//1.calculating the well area for your region of interest          
	open(dir1+blue);
    w1=getTitle();
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
	run("Create Selection");
	close("Results");
	
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
	close("Summary");
	close("Results");

///Excitatory synapse: colocalization of synaptophysin or synpatophysin and PSD95 on MAP2
//2. identify synaptophysin 
open(dir1+green); //open w3
run("Select None");
w3 = getTitle();
run("Set Scale...", "distance=6.1538 known=1 pixel=1 unit=µm global"); //40X mag
close("Results");
run("Set Measurements...", "area mean standard modal min center perimeter shape integrated median area_fraction display redirect=None decimal=3");
run("Remove Outliers...", "radius=2 threshold=50 which=Bright"); //removing objects with intensities 50x (outliers)
selectImage("background_area");
run("Create Selection");
selectImage(w3);
run("Restore Selection");
run("Measure");
image_mean = getResult("Mean", 0);
print(image_mean);
close("Results");
selectImage(w3);
run("Select None");
run("Select All");
run("Measure");
run("Enhance Contrast", "saturated=0.35");
setOption("ScaleConversions", true);
run("Select None");
// change cropped out intensity to the mean intensity of your cropped area. this allows for background subtraction without producing edge effect
image_mean = getResult("Mean", 0);
changeValues(getResult("Mode", 0), getResult("Mode", 0), image_mean);
run("8-bit");
close("Results");


//Background subtraction 
run("Subtract Background...", "rolling=50 sliding");
run("Enhance Contrast", "saturated=0.35");

run("Auto Threshold", "method=Moments white");
run("Create Mask");
rename("synaptophysin_moments");
run("Despeckle");
run("Despeckle");
run("Despeckle");
run("Despeckle");
	
selectWindow("synaptophysin_moments");
w3 = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "synaptophysin_" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	

//3. identify MAP2
open(dir1+red);
w2=getTitle();
run("Remove Outliers...", "radius=2 threshold=50 which=Bright"); //removing objects with intensities 50x (outliers)
selectImage("background_area");
run("Create Selection");
selectImage(w2);
run("Restore Selection");
run("Measure");
image_mean = getResult("Mean", 0);
print(image_mean);
close("Results");
selectImage(w2);
run("Select None");
run("Select All");
run("Measure");
run("Enhance Contrast", "saturated=0.35");
setOption("ScaleConversions", true);
run("Select None");
// change cropped out intensity to the mean intensity of your cropped area. this allows for background subtraction without producing edge effect
image_mean = getResult("Mean", 0);
changeValues(getResult("Mode", 0), getResult("Mode", 0), image_mean);
run("8-bit");
close("Results");
run("Subtract Background...", "rolling=200");
run("Auto Local Threshold", "method=Phansalkar radius=75 parameter_1=0 parameter_2=0 white");
run("Convert to Mask");
rename("map2");
w2=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "map2_" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.
	


///4. colocalizing synaptophysin ROI with MAP2 ROI

imageCalculator("AND create", w2,w3);
rename("synaptophysin_map2_mask1"); 
run("Analyze Particles...", "size=5-Infinity exclude add");

////////getting rid of edge/////////
  selectImage("just_edge");
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
		      if (getResult("%Area", l)>0) {
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

// create new overlay image with ROIs - no-edge map2+synaptophysin ROIs
newImage("synaptophysin_map2_no_edge", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("synaptophysin_map2_"+ list[j-4]); 
w6=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "synaptophysin_map2_" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.


// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Summary");
	close("Results");
	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
//5. identify PSD95
open(dir1+cy5);
run("Select None");
w4 = getTitle();
run("Set Scale...", "distance=6.1538 known=1 pixel=1 unit=µm global"); //40X mag
close("Results");
run("Set Measurements...", "area mean standard modal min center perimeter shape integrated median area_fraction display redirect=None decimal=3");
run("Remove Outliers...", "radius=2 threshold=50 which=Bright"); //removing objects with intensities 50x (outliers)
selectImage("background_area");
run("Create Selection");
selectImage(w4);
run("Restore Selection");
run("Measure");
image_mean = getResult("Mean", 0);
print(image_mean);
close("Results");
selectImage(w4);
run("Select None");
run("Select All");
run("Measure");
run("Enhance Contrast", "saturated=0.35");
setOption("ScaleConversions", true);
run("Select None");
// change cropped out intensity to the mean intensity of your cropped area. this allows for background subtraction without producing edge effect
image_mean = getResult("Mean", 0);
changeValues(getResult("Mode", 0), getResult("Mode", 0), image_mean);
run("8-bit");
close("Results");


//Background subtraction 
run("Subtract Background...", "rolling=50 sliding");
run("Enhance Contrast", "saturated=0.35");
run("Auto Threshold", "method=Otsu white");
run("Create Mask");
rename("psd95_otsu");
run("Despeckle");
run("Despeckle");
run("Despeckle");
run("Despeckle");
selectWindow("psd95_otsu");
w4 = getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "psd95_" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.



///6.colocalizing psd95 ROI with MAP2 ROI

imageCalculator("AND create", w2,w4);
rename("psd95_map2_"+ list[j-4]); 
w7=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "psd95_map2_" + list[j-4] + ".jpg"); //this line will save  mask of each image to results folder. it's helpful to identify any unusual masks.

selectWindow(w7);
run("Analyze Particles...", "size=5-Infinity exclude add");

/////////////////////////////////////////////////////////////////////////////////////////////////////
//7. colocalize MAP2+PSD95 ROI with MAP2+ synaptophysin mask

//select your map2+synaptophysin binary image

	selectWindow(w3);
	run("Select None");
		
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}

measurements = newArray(getValue("results.count"));
//print(measurements.length);
for (l=0; l<measurements.length; l++) {
	      if (getResult("%Area", l)<50) { //50%overlap 
	      measurements[l] = l;
	  }
}
		roiManager("select", measurements);
		roiManager("Delete");



////////getting rid of edge/////////
  selectImage("just_edge");
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
		      if (getResult("%Area", l)>0) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    //selectImage(w3);
	run("Select None");
	close("Results");

////////////////////////////////


// selecting and combining all excitatory synapses ROIs
count = roiManager("count");
array = newArray(count);
  for (l=0; l<array.length; l++) {
      array[l] = l;
  }
roiManager("select", array);
roiManager("Combine");


// create new overlay image with ROIs - exc.synapse
newImage("exct_synapses", "8-bit black", image_width, image_height, 1);
run("Restore Selection");
run("Create Mask");
rename("exct_synapses_"+ list[j-4]); 
w5=getTitle();
run("Duplicate...", " ");
saveAs("jpg", dir2+ "exct_synapses_" + list[j-4] + ".jpg"); //this line will save synaptophysin mask of each image to results folder. it's helpful to identify any unusual masks.

//clearing roi manager
close("Results");


selectImage(w6); 
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); 

selectImage(w7);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); 

selectImage(w5);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize"); 

selectImage("background_area");
rename("background_area_" + list[j-4]);
run("Select None");
run("Remove Overlay");
run("Analyze Particles...", "size=0-Infinity summarize");


// save results	
	selectWindow("Summary");
	saveAs("results", dir2+"Synapse_%area " + list[j-4] + ".txt");
	roiManager("Delete");
	close("Results");
	close("Summary");
	close("Threshold");  
	close("ROI Manager");
	close(w1);
	close(w2);
	close(w3);
	close(w4);
	close(w5);
	close("Untitled");
	close("Results");
    close("*");
    close("*.txt");
	run("Close All");
	showProgress(i, list.length);
          first += 4;
      }


	
  }
	
//exit;


waitForUser("complete, Click Okay");

	