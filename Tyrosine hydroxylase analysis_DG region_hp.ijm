//tyrosine hydroxylase (TH) analysis for DG hippocampal subregion

  // assign  TH - _w2 at the end of the image file name
 
 Dialog.create("Assign Channel ID");
  Dialog.addString("Green Image Suffix:", "w2");//TH

  //Dialog.show();//delete this line to hide the dialog box if you always have the same image suffix per color
  greenSuffix = Dialog.getString() + ".";
  batchCount();

  function batchCount() {
      dir1 = getDirectory("Choose Image Folder to Analyze");
      name = File.getName(dir1);
      dir2 = getDirectory("Select Folder to Save Results");
      list = getFileList(dir1);
      setBatchMode(false);
      //set to false allows us to see the images load as imagej is processing for manual threshold. set to [true] for blind folder batch processing
      n = list.length;
      if ((n%1)!=0)
         exit("The number of files must be a multiple of 1");
      stack = 0;
      first = 0;
      for (i=0; i<n/1; i++) {
          showProgress(i+1, n/2);
          green="?"; blue="?";
          for (j=first; j<first+1; j++) { 
              if (indexOf(list[j], greenSuffix)!=-1)
                  green = list[j];

          } 
          

// the macro starts by designating the well area. we crop brain regions of interest from larger 
// images, so our regions are not uniform. since you are working with wells your images should
// be more uniform size. feel free to remove this section, if it is unnecessary. 

//1. calculating the well area for your region of interest      
/////////////////////////////////////////////////////////////
  
/////////////////////////////////////////////////////////////
	open(dir1+green);
    w3=getTitle();
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
	close(w3);
	
	
// clear the roi manager
	if (roiManager("count") > 0) {
	roiManager("delete");
	}
	close("Summary");
	close("Results");





/// segmenting TH


	open(dir1+green);
    w3=getTitle();
	run("Select None");
	close("Results");
    
    image_width = getWidth();
    image_height = getHeight();

	width = (getWidth()*0.05);
	//	print(width);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	changeValues(0, 0, getResult("Mean",0));
	close("Results");

	run("Subtract Background...", "rolling=300");

    run("Restore Selection");
	run("Measure");
	run("Select None");
	avg = getResult("Mean", 0);
	run("Subtract...", "value=avg");	

	
	run("8-bit");
	run("Auto Local Threshold", "method=Phansalkar radius=200 parameter_1=0 parameter_2=0 white");
	run("Convert to Mask");
	run("Despeckle");
	close("Results");
	run("Set Measurements...", "area mean standard min center perimeter shape integrated median skewness kurtosis area_fraction display redirect=None decimal=3");
	rename("TH_weka");
	close("w3");
	selectImage("TH_weka");
	

	run("Analyze Particles...", "size=10-Infinity show=Nothing add");
	
	run("Set Measurements...", "area mean standard min center perimeter shape integrated median skewness kurtosis area_fraction display redirect=None decimal=3");
			
	open(dir1+green);
    w3=getTitle();
    selectImage(w3);
	run("Select None");
	close("Results");
    
    image_width = getWidth();
    image_height = getHeight();

	width = (getWidth()*0.05);
	//	print(width);
    run("Restore Selection");
	run("Measure");
	run("Select None");
	changeValues(0, 0, getResult("Mean",0));
	close("Results");

	run("Subtract Background...", "rolling=300");

	
    run("Restore Selection");
	run("Measure");
	run("Select None");
	avg = getResult("Mean", 0);
	close("Results");
	run("Subtract...", "value=avg");	
    run("Restore Selection");
	run("Measure");
	
    run("Restore Selection");
	run("Measure");
	
	///// make changes to filtering criteria here//////////////////
	//////////////////////////////////////////////////////////
	    ////////////////////////////////////////////////////////////////////////
	        ////////////////////////////////////////////////////////////////////////
	            ////////////////////////////////////////////////////////////////////////
	                ////////////////////////////////////////////////////////////////////////
	sd = (getResult("StdDev", 1)/1);
	max = (getResult("Mean", 1)*5);
    tissue_mean = (getResult("Mean", 1)+(getResult("StdDev", 1))*0.75);
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////
                ////////////////////////////////////////////////////////////////////////
                
    print(sd);
        print(max);
            print(tissue_mean);
    // move to image to compare rois against.
    
    selectImage("just_edge");
	run("Select None");
	close("Results");
	
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
		      if (getResult("%Area", l)>0) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
		roiManager("Delete");

    
    selectImage(w3);
	run("Select None");
	close("Results");
// create a new array that is equal in length to the number of rois contained in the roi manager. then measure all of the rois in the array
	count = roiManager("count");
	array = newArray(count);
	  for (l=0; l<array.length; l++) {
	      array[l] = l;
	  }
	roiManager("select", array);
		if (roiManager("count") > 1) {
			roiManager("Measure");
	}
	Array.print(array);

/// creat a new array. populate it with all of those rois that do not meet our criteria. using the new array, delete all of those rois from the manager. 
/// make adjustments here. 
	measurements = newArray(getValue("results.count"));
	//print(measurements.length);
	for (l=0; l<measurements.length; l++) {
		      if (getResult("Mean", l)<tissue_mean ) {
		      measurements[l] = l;
		  }
	}
		roiManager("select", measurements);
	//	waitForUser;

		roiManager("Delete");  







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

// creating a new mask of just dapi objects > 10um2 and your given percentage overlap with gfap+ objects
	newImage("TH", "8-bit black", image_width, image_height, 1);
	run("Restore Selection");
	run("Create Mask");
	close("TH");
	selectWindow("Mask");
	rename("TH_mask") ;
	run("Duplicate...", "title=TH_mask");
	saveAs("jpg", dir2 + "TH_mask_" + list[j-1] + ".jpg");
	
// clear the roi manager
if (roiManager("count") > 0) {
	roiManager("delete");
	}




selectImage("background_area");
rename("background+" + list[j-1]);
run("Create Selection");
run("Measure");

open(dir1+green);
w6= getTitle();

selectImage("TH_mask");
rename("TH+"+ list[j-1]);

run("Create Selection");
run("Measure");


//////////////////////////////////

selectWindow("Results");
saveAs("results", dir2+"TH_area+" + list[j-1] + ".txt");

close("Results");
	close("Summary");
	close("Threshold");  
	close("ROI Manager");
    close("*");
    close("*.txt");
	showProgress(i, list.length);
          first += 1;
      }
  }


Dialog.create("DONE");
Dialog.show();
exit;
	




