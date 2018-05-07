module utils.vertexcache;


extern(C):

void stsvco_optimize(uint* indices, uint numIndices, uint numVertices, int cacheSize = 32);
float stsvco_compute_ACMR(in uint* indices, uint numIndices, uint cacheSize = 32);
