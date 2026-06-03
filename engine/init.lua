-- KeyDeck engine — dedicated-config entry point (engine IS ~/.hammerspoon).
-- For coexisting with an existing config, install the Spoon instead (KeyDeck.spoon).
-- All behavior lives in keydeck.lua + lib/ + modules/.
--
-- Credit: Artur Grochau – github.com/arturgrochau
package.path = hs.configdir .. "/?.lua;" .. hs.configdir .. "/?/init.lua;" .. package.path
require("keydeck").start()
