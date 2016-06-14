select tip,contract,data,tert,
(select * from pozcon p where p.Contract='10000015' for xml raw, type)
	from pozcon pp where pp.Contract='10000015' for xml raw