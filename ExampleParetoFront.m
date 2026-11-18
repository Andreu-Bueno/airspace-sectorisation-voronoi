clear;
clc;
close all;
addpath functions_student\

a = 25;
b = 25;
N = 120;

obj1 = a + rand(1, N) * 200;
obj2 = b + rand(1, N) * 300;

paretoPlots(obj1, obj2)
