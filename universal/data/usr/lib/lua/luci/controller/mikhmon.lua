module("luci.controller.mikhmon", package.seeall)
function index()
entry({"admin", "services", "mikhmon"}, template("mikhmon"), _("Mikhmon"), 2).leaf=true
end
