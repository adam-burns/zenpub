# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Uploads.ImageUploader do
  use MoodleNet.Uploads.Definition

  def valid?(file) do
    true
  end

  def transform(file) do
    :skip
  end
end
