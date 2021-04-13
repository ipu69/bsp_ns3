# Build from the MATLAB base image
FROM mathworks/matlab:r2021a

# Copy your script/function to be executed.
COPY get_distance.m ./
COPY get_placement.m ./
COPY get_sta_value.m ./
COPY ILP_problem_coverage_link_cost.m ./
COPY input.json ./

CMD ["matlab","get_placement.m"]
