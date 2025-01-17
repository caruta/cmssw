#include "RiemannFitOnGPU.h"
#include "HeterogeneousCore/CUDAUtilities/interface/device_unique_ptr.h"

template <typename TrackerTraits>
void HelixFitOnGPU<TrackerTraits>::launchRiemannKernels(const TrackingRecHitSoAConstView<TrackerTraits> &hv,
                                                        uint32_t nhits,
                                                        uint32_t maxNumberOfTuples,
                                                        cudaStream_t stream) {
  assert(tuples_);

  auto blockSize = 64;
  auto numberOfBlocks = (maxNumberOfConcurrentFits_ + blockSize - 1) / blockSize;

  //  Fit internals
  auto hitsGPU = cms::cuda::make_device_unique<double[]>(
      maxNumberOfConcurrentFits_ * sizeof(riemannFit::Matrix3xNd<4>) / sizeof(double), stream);
  auto hits_geGPU = cms::cuda::make_device_unique<float[]>(
      maxNumberOfConcurrentFits_ * sizeof(riemannFit::Matrix6x4f) / sizeof(float), stream);
  auto fast_fit_resultsGPU = cms::cuda::make_device_unique<double[]>(
      maxNumberOfConcurrentFits_ * sizeof(riemannFit::Vector4d) / sizeof(double), stream);
  auto circle_fit_resultsGPU_holder =
      cms::cuda::make_device_unique<char[]>(maxNumberOfConcurrentFits_ * sizeof(riemannFit::CircleFit), stream);
  riemannFit::CircleFit *circle_fit_resultsGPU_ = (riemannFit::CircleFit *)(circle_fit_resultsGPU_holder.get());

  for (uint32_t offset = 0; offset < maxNumberOfTuples; offset += maxNumberOfConcurrentFits_) {
    // triplets
    kernel_FastFit<3, TrackerTraits><<<numberOfBlocks, blockSize, 0, stream>>>(
        tuples_, tupleMultiplicity_, 3, hv, hitsGPU.get(), hits_geGPU.get(), fast_fit_resultsGPU.get(), offset);
    cudaCheck(cudaGetLastError());

    kernel_CircleFit<3, TrackerTraits><<<numberOfBlocks, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                                 3,
                                                                                 bField_,
                                                                                 hitsGPU.get(),
                                                                                 hits_geGPU.get(),
                                                                                 fast_fit_resultsGPU.get(),
                                                                                 circle_fit_resultsGPU_,
                                                                                 offset);
    cudaCheck(cudaGetLastError());

    kernel_LineFit<3, TrackerTraits><<<numberOfBlocks, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                               3,
                                                                               bField_,
                                                                               outputSoa_,
                                                                               hitsGPU.get(),
                                                                               hits_geGPU.get(),
                                                                               fast_fit_resultsGPU.get(),
                                                                               circle_fit_resultsGPU_,
                                                                               offset);
    cudaCheck(cudaGetLastError());

    // quads
    kernel_FastFit<4, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(
        tuples_, tupleMultiplicity_, 4, hv, hitsGPU.get(), hits_geGPU.get(), fast_fit_resultsGPU.get(), offset);
    cudaCheck(cudaGetLastError());

    kernel_CircleFit<4, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                                     4,
                                                                                     bField_,
                                                                                     hitsGPU.get(),
                                                                                     hits_geGPU.get(),
                                                                                     fast_fit_resultsGPU.get(),
                                                                                     circle_fit_resultsGPU_,
                                                                                     offset);
    cudaCheck(cudaGetLastError());

    kernel_LineFit<4, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                                   4,
                                                                                   bField_,
                                                                                   outputSoa_,
                                                                                   hitsGPU.get(),
                                                                                   hits_geGPU.get(),
                                                                                   fast_fit_resultsGPU.get(),
                                                                                   circle_fit_resultsGPU_,
                                                                                   offset);
    cudaCheck(cudaGetLastError());

    if (fitNas4_) {
      // penta
      kernel_FastFit<4, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(
          tuples_, tupleMultiplicity_, 5, hv, hitsGPU.get(), hits_geGPU.get(), fast_fit_resultsGPU.get(), offset);
      cudaCheck(cudaGetLastError());

      kernel_CircleFit<4, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                                       5,
                                                                                       bField_,
                                                                                       hitsGPU.get(),
                                                                                       hits_geGPU.get(),
                                                                                       fast_fit_resultsGPU.get(),
                                                                                       circle_fit_resultsGPU_,
                                                                                       offset);
      cudaCheck(cudaGetLastError());

      kernel_LineFit<4, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                                     5,
                                                                                     bField_,
                                                                                     outputSoa_,
                                                                                     hitsGPU.get(),
                                                                                     hits_geGPU.get(),
                                                                                     fast_fit_resultsGPU.get(),
                                                                                     circle_fit_resultsGPU_,
                                                                                     offset);
      cudaCheck(cudaGetLastError());
    } else {
      // penta all 5
      kernel_FastFit<5, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(
          tuples_, tupleMultiplicity_, 5, hv, hitsGPU.get(), hits_geGPU.get(), fast_fit_resultsGPU.get(), offset);
      cudaCheck(cudaGetLastError());

      kernel_CircleFit<5, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                                       5,
                                                                                       bField_,
                                                                                       hitsGPU.get(),
                                                                                       hits_geGPU.get(),
                                                                                       fast_fit_resultsGPU.get(),
                                                                                       circle_fit_resultsGPU_,
                                                                                       offset);
      cudaCheck(cudaGetLastError());

      kernel_LineFit<5, TrackerTraits><<<numberOfBlocks / 4, blockSize, 0, stream>>>(tupleMultiplicity_,
                                                                                     5,
                                                                                     bField_,
                                                                                     outputSoa_,
                                                                                     hitsGPU.get(),
                                                                                     hits_geGPU.get(),
                                                                                     fast_fit_resultsGPU.get(),
                                                                                     circle_fit_resultsGPU_,
                                                                                     offset);
      cudaCheck(cudaGetLastError());
    }
  }
}

template class HelixFitOnGPU<pixelTopology::Phase1>;
template class HelixFitOnGPU<pixelTopology::Phase2>;
template class HelixFitOnGPU<pixelTopology::HIonPhase1>;
