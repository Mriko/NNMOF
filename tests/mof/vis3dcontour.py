import numpy as np
import h5py
from mayavi import mlab
f = h5py.File('visual.h5','r')
for key in f['visual']:
    vis = np.array(f['visual'][key])
    mlab.contour3d(vis,contours=8,opacity=.2 )
nx, ny, nz = vis.shape
f.close()
mlab.outline(extent=[0,nx,0,ny,0,nz])
mlab.show()
