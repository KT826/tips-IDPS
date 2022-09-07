function CCout = cal_CC(base_frame_data,f,Frame_num,FrameResize)


CCout=[];
parfor f2 = 1 : Frame_num

    frame_data = FrameResize{f2};
    r = corrcoef(double(base_frame_data),double(frame_data));
    CCout(f2) = r(2);
end

end