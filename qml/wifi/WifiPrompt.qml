pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Networking as Nm
import qs
import qs.components
import qs.services

PromptWindow {
    id: root

    readonly property Nm.WifiNetwork network: Network.asking
    property string failure: ""

    namespace: "omde-wifi"
    shown: network !== null
    onDismissed: Network.asking = null
    onShownChanged: {
        failure = "";
        prompt.input.text = "";
        if (shown)
            prompt.input.forceActiveFocus();
    }

    Connections {
        target: root.network
        function onConnectedChanged() {
            if (root.network.connected)
                Network.asking = null;
        }
        function onConnectionFailed(reason) {
            root.failure = reason === Nm.ConnectionFailReason.NoSecrets ? "wrong password"
                : Nm.ConnectionFailReason.toString(reason).toLowerCase();
        }
    }

    PasswordPrompt {
        id: prompt
        width: parent.width
        header: "join " + (root.network?.name ?? "")
        glyph: Icons.secured
        placeholder: "password"
        status: root.failure || (root.network?.stateChanging ? "connecting…" : "")
        error: root.failure.length > 0
        onSubmitted: password => {
            root.failure = "";
            root.network.connectWithPsk(password);
        }
        onCancelled: root.dismissed()
    }
}
