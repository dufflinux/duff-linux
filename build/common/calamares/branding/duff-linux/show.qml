/* === This file is part of Calamares - <https://calamares.io> ===
 *
 *   SPDX-FileCopyrightText: 2015 Teo Mrnjavac <teo@kde.org>
 *   SPDX-FileCopyrightText: 2018 Adriaan de Groot <groot@kde.org>
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Calamares is Free Software: see the License-Identifier above.
 *
 */

import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        console.log("QML Component (default slideshow) Next slide");
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 7500
        running: true
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Text {
            anchors.centerIn: parent
            text: "🍻<br/><br/><b>Welcome to Duff Linux</b><br/><br/>" +
                  "A personal, opinionated distro built on Void Linux.<br/>" +
                  "KDE Plasma · Btrfs Snapshots · Rolling Release"
            wrapMode: Text.WordWrap
            width: presentation.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 14
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            text: "🖥️<br/><br/><b>KDE Plasma Desktop</b><br/><br/>" +
                  "A full-featured, modern desktop environment.<br/>" +
                  "Breeze Dark theme out of the box, with Wayland support."
            wrapMode: Text.WordWrap
            width: presentation.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 14
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            text: "📸<br/><br/><b>Automatic Btrfs Snapshots</b><br/><br/>" +
                  "Every package transaction is backed up automatically.<br/>" +
                  "Boot into any snapshot from the GRUB menu to restore your system."
            wrapMode: Text.WordWrap
            width: presentation.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 14
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            text: "📦<br/><br/><b>Package Management</b><br/><br/>" +
                  "Native packages via OctoXBPS with update notifications.<br/>" +
                  "Flatpak support with Flathub pre-configured via Discover."
            wrapMode: Text.WordWrap
            width: presentation.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: 14
        }
    }

    function onActivate() {
        console.log("QML Component (default slideshow) activated");
        presentation.currentSlide = 0;
    }

    function onLeave() {
        console.log("QML Component (default slideshow) deactivated");
    }

}
