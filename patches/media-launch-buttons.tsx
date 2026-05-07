import { execAsync } from 'astal';
import { Gtk } from 'astal/gtk3';
import { isPrimaryClick } from 'src/lib/events/mouse';
import { Astal, Widget } from 'astal/gtk3';

export const LaunchButtons = (): JSX.Element => {
    return (
        <box className={'media-launch-buttons'} halign={Gtk.Align.CENTER} spacing={12}>
            <button
                className={'media-launch-button'}
                hasTooltip
                tooltipText={'Open Spotify'}
                onClick={(_: Widget.Button, event: Astal.ClickEvent) => {
                    if (!isPrimaryClick(event)) return;
                    execAsync('spotify').catch(() => {});
                }}
            >
                <label label={'  Spotify'} />
            </button>
            <button
                className={'media-launch-button'}
                hasTooltip
                tooltipText={'Open YouTube Music'}
                onClick={(_: Widget.Button, event: Astal.ClickEvent) => {
                    if (!isPrimaryClick(event)) return;
                    execAsync('pear-desktop').catch(() => {});
                }}
            >
                <label label={'  YT Music'} />
            </button>
        </box>
    );
};
