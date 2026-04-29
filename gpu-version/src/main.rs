use {
    anyhow::{Context, Result},
    winit::{
        event::{Event, WindowEvent},
        event_loop::{ControlFlow, EventLoop},
        window::{Window, WindowBuilder},
    },
};

mod render;

const WIDTH: u32 = 800;
const HEIGHT: u32 = 600;

async fn connect_to_gpu<'a>(
    window: &'a Window,
) -> Result<(
    wgpu::Device,
    wgpu::Queue,
    wgpu::Surface<'a>,
    wgpu::TextureFormat,
)> {
    use wgpu::TextureFormat::{Bgra8Unorm, Rgba8Unorm};

    // create wgpu instance to access api
    let instance = wgpu::Instance::default();

    let surface = instance.create_surface(window)?;

    // request best compatible adapter (physical gpu)
    let adapter: wgpu::Adapter = instance
        .request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            force_fallback_adapter: false,
            compatible_surface: Some(&surface),
        })
        .await
        .context("failed to find a compatible adapter")?;

    // connect to gpu
    let (device, queue): (wgpu::Device, wgpu::Queue) = adapter
        .request_device(&wgpu::DeviceDescriptor::default())
        .await
        .context("failed to connect to the GPU")?;

    // config texture mem backing surface
    let caps = surface.get_capabilities(&adapter);
    let format = caps
        .formats
        .into_iter()
        .find(|it| matches!(it, Rgba8Unorm | Bgra8Unorm))
        .context("preferred texture format no found/supported")?;
    
    let size = window.inner_size();

    let config = wgpu::SurfaceConfiguration {
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
        format,
        width: size.width,
        height: size.height,
        present_mode: wgpu::PresentMode::AutoVsync,
        alpha_mode: caps.alpha_modes[0],
        view_formats: vec![],
        desired_maximum_frame_latency: 3,
    };
    surface.configure(&device, &config);

    Ok((device, queue, surface, format))
}

#[pollster::main]
async fn main() -> Result<()> {
    let event_loop = EventLoop::new()?;
    let window_size = winit::dpi::PhysicalSize::new(WIDTH, HEIGHT);
    let window = WindowBuilder::new()
        .with_inner_size(window_size)
        .with_resizable(false)
        .with_title("GPU Path Tracer".to_string())
        .build(&event_loop)?;
    let (device, queue, surface, surface_format) = connect_to_gpu(&window).await?;

    // TODO: initialize renderer
    let renderer = render::PathTracer::new(device, queue, surface_format);

    event_loop.run(|event, control_handle| {
        control_handle.set_control_flow(ControlFlow::Poll);
        match event {
            Event::WindowEvent { event, .. } => match event {
                WindowEvent::CloseRequested => control_handle.exit(),
                WindowEvent::RedrawRequested => {
                    // Wait for the next available frame buffer.
                    let frame: wgpu::SurfaceTexture = surface
                        .get_current_texture()
                        .expect("failed to get current texture");

                    let render_target = frame
                        .texture
                        .create_view(&wgpu::TextureViewDescriptor::default());
                    
                    renderer.render_frame(&render_target);

                    frame.present();
                    window.request_redraw();
                }
                _ => (),
            },
            _ => (),
        }
    })?;
    Ok(())
}
