use cosmic::app::Core;
use cosmic::{Action, Element, Task};

use cosmic::widget::{text, button};
use std::time::Duration;

const ID: &str = "io.ocf.paper-genmon-applet";

#[derive(Default)]
pub struct Window {
    core: Core,
    panel_text: String, // Field stores paper genmon output
}

#[derive(Clone, Debug)]
pub enum Message {
    Tick,                // Changed by timer
    UpdateText(String),  // Called with result of paper genmon command
}

impl cosmic::Application for Window {
    type Executor = cosmic::SingleThreadExecutor;
    type Flags = ();
    type Message = Message;
    const APP_ID: &'static str = ID;

    fn core(&self) -> &Core {
        &self.core
    }

    fn core_mut(&mut self) -> &mut Core {
        &mut self.core
    }

    fn init(core: Core, _flags: Self::Flags) -> (Self, Task<Action<Self::Message>>) {
        let window = Window {
            core,
            panel_text: String::from("Loading page count..."), // Initial text
            ..Default::default()
        };

        // Run the command immediately on startup
        (window, Task::done(Message::Tick).map(Action::from))
    }

    // Background timer for refreshing every 5 seconds
    fn subscription(&self) -> cosmic::iced::Subscription<Self::Message> {
        cosmic::iced::time::every(Duration::from_secs(5))
            .map(|_| Message::Tick)
    }

    fn update(&mut self, message: Message) -> Task<Action<Self::Message>> {
        match message {
            Message::Tick => {
                return Task::perform(
                    async {
                        let output = std::process::Command::new("paper-genmon")
                            .output()
                            .ok();

                        if let Some(out) = output {
                            String::from_utf8_lossy(&out.stdout).trim().to_string()
                        } else {
                            "Error".to_string()
                        }
                    },
                    Message::UpdateText,
                )
                .map(Action::from);
            }
            Message::UpdateText(new_text) => {
                self.panel_text = new_text;
            }
        }
        Task::none()
    }

    fn view(&self) -> Element<'_, Message> {
        let content = text(&self.panel_text)
            .size(18)
            .width(cosmic::iced::Length::Shrink);

        let button = button::custom(content)
            .class(cosmic::theme::Button::AppletIcon)
            .padding([0, 12]);

        cosmic::widget::autosize::autosize(button, cosmic::widget::Id::unique()).into()
    }
}
