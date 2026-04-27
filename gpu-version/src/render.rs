pub struct PathTracer {
    device: wgpu::Device,
    queue: wgpu::Queue,
}

impl PathTracer {
    pub fn new(device: wgpu::Device, queue: wgpu::Queue) -> PathTracer {
        device.on_uncaptured_error(Box::new(|error| {
            panic!("Aborting due to an error: {}", error);
        }));

        // TODO: initialize GPU resources

        PathTracer {
            device,
            queue,
        }
    }
}