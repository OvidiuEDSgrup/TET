exists (SELECT 1
from pozcon inner join con on con.Subunitate=pozcon.subunitate and con.Tip=pozcon.Tip and con.Contract=pozcon.Contract 
	and con.Data=pozcon.Data and pozcon.Tert=con.Tert
where pozcon.Subunitate=@sub and pozcon.Tip=@tip and isnull(nullif(p.Grupa,''),p.[Contract])=@contract and pozcon.Data=@data and pozcon.Tert=@tert 
	and con.responsabil_tert='1')