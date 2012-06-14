
/* 
   xor_pcases.cu
   Implementation of a XOR neural network in CUDA, 
   calculating output of many input cases in parallel.

   Andrei de A. Formiga, 2012-03-31
*/

#include <stdio.h>


// weights for the hidden layer
float weights_h[] = { 0.5f, -1.0f, -1.0f,
                      -1.5f, 1.0f, 1.0f };

// weights for the output layer
float weights_o[] = { 0.5f, -1.0f, -1.0f };

// weight arrays for the device
float *dev_hw;
float *dev_ow;

// device input
float *dev_in;

// device hidden outputs
float *dev_hidden;

// device output
float *dev_out;

// inputs
float inputs[] = { 0.0f, 0.0f, 0.0f, 1.0f,
                   1.0f, 0.0f, 1.0f, 1.0f };

int ncases = 4;
int input_size = 2;

int hidden_size = 2;

// desired outputs
float outputs[] = { 0.0f, 1.0f, 1.0f, 0.0f };

// kernel for hidden layer
__global__ void calculate_hidden(float *dev_hw, float *input, float *hidden)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int input_ix = blockIdx.x * 2;  // 2 neurons in the previous layer
    int toff = threadIdx.x;
    float h;

    h = dev_hw[toff * 3] * 1.0f +
        dev_hw[toff * 3 + 1] * input[input_ix] +
        dev_hw[toff * 3 + 2] * input[input_ix+1];

    // threshold
    if (h > 0.0f)
        hidden[tid] = 1.0f;
    else
        hidden[tid] = 0.0;
}

// kernel for output layer
__global__ void calculate_output(float *dev_ow, float *hidden, float *output)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int hidden_ix = blockIdx.x * 2;  // 2 neurons in the previous layer
    int toff = threadIdx.x;    
    float o;

    o = dev_ow[toff] * 1.0f +
        dev_ow[toff+1] * hidden[hidden_ix] +
        dev_ow[toff+2] * hidden[hidden_ix+1];

    // threshold
    if (o > 0.0f)
        output[tid] = 1.0f;
    else
        output[tid] = 0.0f;
}

int main(int argc, char **argv)
{
    float out[ncases];

    printf("### XOR test (forward propagation)\n");
    
    cudaMalloc((void**) &dev_hw, 6 * sizeof(float));
    cudaMalloc((void**) &dev_ow, 3 * sizeof(float));
    cudaMalloc((void**) &dev_in, ncases * input_size * sizeof(float));
    cudaMalloc((void**) &dev_hidden, ncases * hidden_size * sizeof(float));
    cudaMalloc((void**) &dev_out, ncases * sizeof(float));  // output size = 1
    
    cudaMemcpy(dev_hw, weights_h, 6 * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_ow, weights_o, 3 * sizeof(float), cudaMemcpyHostToDevice);

    // try inputs
    cudaMemcpy(dev_in, inputs, ncases * input_size * sizeof(float), cudaMemcpyHostToDevice);
    calculate_hidden<<<4, 2>>>(dev_hw, dev_in, dev_hidden);
    calculate_output<<<4, 1>>>(dev_ow, dev_hidden, dev_out);
    cudaMemcpy(out, dev_out, ncases * sizeof(float), cudaMemcpyDeviceToHost);

    for (int i = 0; i < ncases; ++i)
        printf("Input: %2.1f %2.1f -- Output: %f\n", inputs[input_size*i],
               inputs[input_size*i+1], out[i]);
    
    cudaFree(dev_hw);
    cudaFree(dev_ow);
    cudaFree(dev_in);
    cudaFree(dev_hidden);
    cudaFree(dev_out);
    
    return 0;
}
