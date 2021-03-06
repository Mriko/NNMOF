import matplotlib.pyplot as plt

x = [[0,0],[0,4],[4,4],[4,0]]
y = [[0,4],[4,4],[4,0],[0,0]]

x1 = [[0,0],[0,2],[2,2],[2,0],[0,0],[0,2],[2,2],[2,0],[2,2],[2,4],[4,4],[2,4],[0,0],[2,4],[4,4],[4,2]]
y1 = [[0,2],[2,2],[2,0],[0,0],[2,4],[4,4],[4,2],[2,2],[2,4],[4,4],[4,2],[2,2],[0,2],[2,2],[2,0],[0,0]]

k = ['r','g']

for i in range(len(x)):
	plt.plot(x[i], y[i], color=k[0])

for i in range(len(x1)):
	plt.plot(x1[i], y1[i], color=k[1])

plt.show()