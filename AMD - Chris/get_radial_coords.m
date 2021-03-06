function [ coord_img ] = get_radial_coords( grid_size,center_x, center_y )
%Returns an image of size = grid_size where each pixel has the values (r,theta), which represent the polar
%coordinates of that pixel given the (fov_x,fov_y) as the origin

[x,y] = meshgrid(1:grid_size(2),1:grid_size(1));
x = x - center_x;
y = y - center_y;

r = sqrt(x.^2+y.^2);
theta = atan2(y,x);
coord_img = cat(3,r,theta);
end

