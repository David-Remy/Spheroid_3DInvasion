/* Tested with ImageJ 1.53c on Windows
 *  macro_spheroid_3dinvasion_v9.ijm
 *  DR/ASM 
 */

/////////////////////////////////////////////////////////////
////// begining of parameters customizable by the user //////
/////////////////////////////////////////////////////////////
// angle of inclinaison, in degrees
AngleInc = 5;
/////////////////////////////////////////////////////////////
//////// end of parameters customizable by the user /////////
/////////////////////////////////////////////////////////////

// Close "Log" window
if (isOpen("Log")) {
	selectWindow("Log");
	run("Close");
}

if( nImages == 0 )
	exit("No image open in Fiji");

getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pixelWidth, pixelHeight);
tit_img = getTitle();
angles = 180/AngleInc;

ROINumber=roiManager("count");
if(ROINumber!=nSlices) exit("Less ROIs than slices in this stack");

//Asks the user to choose a saving directory where the stack and the ROIs will be automatically saved
directory = getDirectory("Choose saving directory...");
roiManager("deselect");
roiManager("save", directory+tit_img+"_ROIs.zip");
selectWindow(tit_img);
saveAs(".tif", directory+tit_img+"_Stack.tif");
tit_img=getTitle();
run("Clear Results");


// Apply mean intensity threshold
Dialog.createNonBlocking("Check background mean intensity");
Dialog.addNumber("Background Mean Intensity", 200);
Dialog.show();
threshold=Dialog.getNumber;

for (i_slice = 0; i_slice < ROINumber; i_slice++) {
	selectWindow(tit_img);
	roiManager("select", i_slice);
	if (selectionType()==10) { // check that the ROI is a point
		getSelectionCoordinates(x, y);
		CentreX=x[0];
		CentreY=y[0];
	}
	else 
		exit("the center of the spheroid is not a point");	

	// computes the size of the line for analysis
	Radius = minOf(CentreX, CentreY)-0.5;
	makeLine(CentreX-Radius, CentreY, CentreX+Radius, CentreY);
	profile=getProfile();
	sum=newArray(lengthOf(profile));

	for (j = 0; j < lengthOf(profile); j++) {
		sum[j]=0;
		profile[j]=0;
	}
	
	// for each angle: profile is computed and added to sum array
	for (i = 0; i <= angles ; i++) {
		angle=(i-angles)*AngleInc;
		EdgeX=Radius*cos(angle*PI/180);
		EdgeY=Radius*sin(angle*PI/180);
		makeLine((CentreX-EdgeX), (CentreY-EdgeY), (CentreX+EdgeX), (CentreY+EdgeY));
		wait(20);
		profile=getProfile();
		for (j = 0; j < lengthOf(profile); j++) {
			sum[j]+=profile[j];
		}
	}
	
	// computation of the mean profile
	for (j = 0; j < lengthOf(profile); j++) {
		sum[j]=sum[j]/angles;
	}

	//Determination of the width of the profile
	// on each side of the center, we search for the first point where 
	// the profile goies below the chosen threshold
	xmin=0;
	xmax=lengthOf(sum);
	width=0;

	// on the left of the profile
	found = false;
	for (j = lengthOf(sum)/2; j>=0 ; j--) {
		if ((sum[j]<threshold) && !found) {
			xmin=j;
			found = true;
		}
	}
	
	// on the right of the profile
	found = false;
	for (j = lengthOf(sum)/2; j<lengthOf(sum); j++) {
		if ((sum[j]<threshold)&& !found) {
			xmax=j;
			found = true;
		}
	}

	// width is computed, converted in the unit of the image and
	// put in the result table
	width=xmax - xmin;
	setResult("Width",i_slice,width);
	setResult("Scaled width",i_slice,width*pixelWidth);

	// saves the plot in the chosen directory
	Plot.create("Width", "Distance", "Intensity", sum);
	Plot.show();
	selectWindow("Width");
	saveAs("png",directory+"average_profile_"+tit_img+"_"+i_slice+1+".png");
	close();
}

saveAs("Results",directory+tit_img+"_spheroid_size.xls");



