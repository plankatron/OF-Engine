local log = require("core.logger")

log.log(log.DEBUG, ":::: Core UI implementation.")

require("core.gui.core")
require("core.gui.core_containers")
require("core.gui.core_spacers")
require("core.gui.core_primitives")
require("core.gui.core_scrollers")
require("core.gui.core_sliders")
require("core.gui.core_buttons")
require("core.gui.core_editors")
require("core.gui.core_misc")

require("core.gui.default")
