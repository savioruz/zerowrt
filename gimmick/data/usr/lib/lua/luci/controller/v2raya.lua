module("luci.controller.v2raya", package.seeall)
function index()
entry({"admin", "services", "v2rayA"}, template("v2raya"), _("v2raya"), 2).leaf=true
end