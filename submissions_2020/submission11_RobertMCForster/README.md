# Timelock Upgrade!

This contract is a bulletproof, totally safe way to upgrade the masterCopy of a proxy contract. The owner of the contract is the only one who can propose and confirm, but they must wait a full month after proposal before it can be confirmed. This ensures users have time to opt-out of the contract if they do not agree with the upgrade.

Just kidding they don't have that time.

On line 66, directly after the "h" in the 'month' comment and directly before the 'h' in the "hour" comment, there are hidden Unicode characters. The first Unicode character is "Right-to-Left Override" (U+202E); the second Unicode character is "Pop Directional Formatting" (U+202C). The RTLO character reverses the direction code is written and read. The Pop Directional Formatting character then stops RTLO from affecting the rest of the line. Unicode can only be used within strings and comments so you have to format this "exploit" pretty specifically for it to not look too suspicious.

By doing this, we can write code that looks perfectly normal but executes in unexpected ways. When we find month and day using Bokky's timestamp library the first time, everything is normal. The second time we use it we've reversed the code in the middle.

While the line looks like:<br>
`(/*year*/, /*month*/ m, /*day*/ d, /*hour*/, /*minute*/, /*second*/) = BokkyDateTime.timestampToDateTime(now);`

it executes (and was typed) as:<br>
`(/*year*/, /*month*/ ,d /*yad*/ ,m /*‬‬hour*/, /*minute*/, /*second*/) = BokkyDateTime.timestampToDateTime(now);`

This means that what should be the current month is actually set as the current hour, so all an owner has to do is call propose and confirm at the hour of the day corresponding to the value of upgrade month and masterCopy can be changed with no time for users to opt out.