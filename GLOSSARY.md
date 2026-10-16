# Shalomly

A white-label church app platform: one shared backend serves many churches, each of which ships its own branded member app.

## Language

### Churches

**Church**:
A congregation on the platform, with its own Members, Theme, and Member App. Everything on the platform belongs to exactly one church, except Super Admins.
_Avoid_: tenant, organization

### Roles

Each person holds exactly one role in their church. A Super Admin may give anyone any role, a Pastor may give any church role, and an Admin may make someone only an Elder or a Member.

**Super Admin**:
Platform staff who manage every church on the platform, not a member of any one congregation's leadership.
_Avoid_: platform admin, global admin

**Pastor**:
A church's spiritual leader, with full management rights over that one church and the only church role a Private Prayer Request can be assigned to. A church may have several.
_Avoid_: assistant pastor, senior pastor

**Admin**:
Church office staff with the same management rights as a Pastor, except that private prayer requests, the authors of anonymous ones, and the giving ledger stay hidden from them. An Admin creates, edits, and deactivates only Elder and Member accounts, and may give only those two roles; a Pastor manages every account except a Super Admin's.
_Avoid_: church admin, secretary, administrator

**Treasurer**:
An Elder who also manages the church's finances (funds, donations, payouts), and has no other management rights.
_Avoid_: finance manager, accountant

**Youth Leader**:
A church role that may post Events, managing only those it created, and may create Groups, becoming their first Group Leader.
_Avoid_: youth committee, youth pastor

**Elder**:
A title for a church's elders and deacons, carrying exactly a Member's rights.
_Avoid_: deacon, committee member

**Member**:
A signed-in person belonging to one church, with no management rights over it.
_Avoid_: user, congregant

### Groups

**Group**:
A set of Members within one church who meet or serve together, such as a Bible study, choir, or youth fellowship. Content for a subset of the church belongs in a Group. A Group is either open, which any Member may join themselves, or closed, which only its Group Leaders, Pastors, and Admins can add Members to; any Member may leave. Every Member can see that a Group exists, but its Group Posts and member list stay within it.
_Avoid_: section, committee, ministry

**Group Leader**:
A Member who leads one Group, managing its membership and Group Posts, with no rights beyond that Group. Whoever creates a Group becomes its first Group Leader; after that, rights over the Group come only from leading it. A Group may have several, appointed by its Group Leaders or the church's Pastors and Admins, or none, in which case its Pastors and Admins manage it until they appoint one. A Member stops being a Group Leader the moment they leave the Group or stop being an active Member.
_Avoid_: co-leader, group owner, group admin

**Archived Group**:
A Group that has ended: hidden from browsing and joining, and its history kept for the church's Pastors and Admins. A Group is archived, never deleted, and a Pastor or Admin may unarchive it, restoring its members and Group Posts.
_Avoid_: deleted group, disbanded group, inactive group

**Group Post**:
A message posted inside one Group by one of its Group Leaders or by a Pastor or Admin, visible only to that Group's members and the church's Pastors and Admins. Other Members of the Group read but do not post. Its author may edit or delete it; the Group's other Group Leaders and the church's Pastors and Admins may delete it. Deletion is permanent. A Group Post may point to an Event, showing the Event's current details; that is how an Event is shared with a Group. Content meant for a subset of the church is a Group Post, never an Event.
_Avoid_: group message, group announcement

### Calendar

**Event**:
Anything a church puts on its calendar for the whole church, on a set date and start time: a gathering, such as a worship service, a fellowship, or a conference, or a Notice. Every Event has exactly one Event Type. It may carry text, a PDF (such as a worship service's order of service or a conference program), and an image. It is posted by a Pastor, Admin, or Youth Leader. Each Event is its own record, even when the same gathering happens every week, because the details, such as who leads it, change from week to week.
_Avoid_: bulletin, announcement, service time, group event, section event

**Event Type**:
The one kind an Event is, from a fixed list shared by every church: worship, fellowship, conference, Bible study, prayer meeting, outreach, celebration, notice, or other. It says what kind of thing the Event is, never who it is for.
_Avoid_: category, tag, youth event

**Notice**:
An Event that is not a gathering but something the church should know about on a date, such as "Church office closed Monday".
_Avoid_: announcement, alert

### Sermons

**Sermon**:
A recorded sermon the church publishes as a public YouTube video, shown in its app to anyone, signed in or not, from the moment a Pastor or Admin adds it. It carries the date it was preached and its Preacher, who need not be a member of the church.
_Avoid_: message, video

**Preacher**:
Whoever preached a Sermon, named as free text so guest speakers can be credited.
_Avoid_: speaker, pastor (when meaning the preacher of one Sermon)

### Prayer

**Prayer Request**:
Something a Member asks their church to pray for, either on the Prayer Chain or as a Private Prayer Request.
_Avoid_: prayer post, prayer item

**Prayer Chain**:
A church's shared list of Prayer Requests that every Member of that church can see.
_Avoid_: prayer wall, public chain, prayer board

**Private Prayer Request**:
A Prayer Request kept off the Prayer Chain and visible only to its author, its Assigned Pastor, and Super Admins. Other Pastors do not know it exists.
_Avoid_: pastor-only request, confidential request

**Assigned Pastor**:
The one Pastor a Private Prayer Request is entrusted to, chosen by its author and changeable by the author or by the Assigned Pastor handing it to another Pastor. A Pastor may not be assigned their own request. Validity is judged at read time against the Pastor's current role and active status: if the Assigned Pastor stops being an active Pastor, the request goes back to its author until they choose another.
_Avoid_: owner, handler, assignee

**Anonymous Prayer Request**:
A Prayer Chain request whose author is hidden from other Members, though never from the Pastors. A Private Prayer Request is never anonymous.
_Avoid_: hidden request

**Intercession**:
A Member's standing commitment to pray for someone else's open Prayer Request on the Prayer Chain, which they can withdraw.
_Avoid_: prayer, like, amen

**Pastoral Prayer**:
A dated record that the Assigned Pastor has prayed for a Private Prayer Request, optionally with a short one-way note to its author. It applies only to Private Prayer Requests, can be added many times, never gates the request's status, and is append-only: once recorded it cannot be edited or deleted. Readable by the request's author, the Pastor who recorded it, and Super Admins.
_Avoid_: prayed mark, acknowledgement, pastoral note

**Answered**:
A Prayer Request the author has marked as answered, optionally with a note on how it was answered.
_Avoid_: resolved, fulfilled

**Closed**:
A Prayer Request that no longer needs prayer, closed by its author, by a Pastor or Admin moderating the Prayer Chain, or by the Assigned Pastor of a Private Prayer Request. The author can reopen it unless it was closed for moderation.
_Avoid_: archived, removed, deleted

### Apps

**Member App**:
The app a church's Members use, published under that church's own name and icon and tied to it by its App Key. Every church's Member App comes from the same shared codebase.
_Avoid_: white-label app, tenant app, church app

**App Key**:
The public identifier that ties a Member App to its church. It is not a secret.
_Avoid_: tenant key, church code

**Church Workspace**:
The web workspace where people holding management rights in a church manage it, each seeing only what their role allows. Members use their church's Member App instead.
_Avoid_: CMS, admin panel, dashboard, church desktop, back office

**Theme**:
The light- and dark-mode colors and the logo a church's Member App is drawn in, changeable by that church's Pastors and Admins or a Super Admin and visible to anyone, signed in or not. The app's icon, store name, and splash screen belong to its Member App, not its Theme.
_Avoid_: branding, skin, palette, colors

**Default Theme**:
The platform's colors, which a church's Member App uses for every color its Theme leaves unchosen and that isn't a Generated Color. When the platform changes its Default Theme, every church follows it for those colors.
_Avoid_: base theme, fallback colors, Shalomly theme

**Generated Colors**:
The colors worked out from a church's chosen primary color for every other color its Theme leaves unchosen, so picking one color is enough for a Theme of its own. The status colors (success, warning, error, info) are never generated. Generated Colors are worked out each time the Theme is read and never stored, so they aren't the church's choices.
_Avoid_: derived colors, auto colors, palette
