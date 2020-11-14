// ----------------------------------------------------------------------------
// Project1.cpp
// ----------------------------------------------------------------------------

#include "pch.h"

int main(int atgc, char** argv)
{
	cv::Mat frame;
	cv::VideoCapture cap;
	int deviceID = 0;             // 0 = open default camera
	int apiID = cv::CAP_ANY;      // 0 = autodetect default API
								  // open selected camera using selected API
	cap.open(deviceID, apiID);
	if (!cap.isOpened())
	{
		std::cerr << "ERROR! Unable to open camera\n";
		return -1;
	}

	std::cout << "Start grabbing" << std::endl << "Press any key to terminate" << std::endl;
	for (;;)
	{
		cap.read(frame);
		if (frame.empty())
		{
			std::cerr << "ERROR! blank frame grabbed\n";
			break;
		}

		cv::imshow("Live", frame);
		if (cv::waitKey(5) >= 0)
			break;
	}

	return 0;
}