import math

import time
from matplotlib import cm
from matplotlib import gridspec
from matplotlib import pyplot as plt
import numpy as np
import sklearn
from sklearn.tree import DecisionTreeRegressor



# Load Training Date and test data
f = np.loadtxt('DATA/Linear_Training_2D.dat',unpack='true')
f2 = np.loadtxt('DATA/Linear_Test_2D.dat',unpack='true')

# X: training input data    y: training output data
# X2: test inut data 
# (It is weird that although I put 0:3 and 3:6, it is actually actually 0:2, 3:5 columns.
#    Not sure if there is somthing wron, on my laptop) 
X = np.transpose(f[0:3,:])
y = np.transpose(f[4:7,:])
y11 = np.transpose(f[4:5,:])
y12 = np.transpose(f[5:6,:])
y13 = np.transpose(f[6:7,:])

# to change the range of test data, sinply change the subscripts or import other data.
n_test = 10
L = np.zeros((n_test,7))
X2 = np.transpose(f2[0:3,:])
Y3 = np.transpose(f2[4:7,:])
n_test = X2.shape[0]


# y = np.zeros((len(f[0]),2))
# X = np.transpose(f[3:6,:])
# y[:,0] =  np.transpose(f[0,:])
# y[:,1] =  np.transpose(f[2,:])
# # to change the range of test data, sinply change the subscripts or import other data.
# n_test = 10
# L = np.zeros((n_test,6))
# for i in range(0,n_test):
# 	L[i,:] = np.transpose(f2[:,np.random.randint(low = 1,high = len(f2[0]))])
# 	X2 = L[:,3:6]
# 	Y3 = L[:,0:3]

# sklean stuff
regr =DecisionTreeRegressor(criterion='mse', splitter='best', max_depth=None, \
				min_samples_split=2, min_samples_leaf=1, min_weight_fraction_leaf=0, \
				max_features='auto', random_state=None, max_leaf_nodes=None, \
				min_impurity_decrease=0.0, min_impurity_split=None, presort=False)

# Linear fit
regr.fit(X,y11)
# predict the results with test data input
y21 = regr.predict(X2)

# Linear fit
regr.fit(X,y12)
# predict the results with test data input
y22 = regr.predict(X2)

# Linear fit
regr.fit(X,y13)
# predict the results with test data input
y23 = regr.predict(X2)
 


L1_error_xnorm_dt  = sum(abs(y21[:]-Y3[:,0])) / n_test
L1_error_ynorm_dt  = sum(abs(y22[:]-Y3[:,1])) / n_test
L1_error_area_dt  = sum(abs(y23[:]-Y3[:,2]))  / n_test

print(L1_error_xnorm_dt)
print(L1_error_ynorm_dt)
print(L1_error_area_dt)



print(regr.tree_.node_count)

# s = [[0.44478960,  0.25759843,  0.08658359]]

# array([[0.51448255, 0.78183238, 0.31944274]])