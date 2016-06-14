select 
--update con set stare = 
--select 
--(select sign(pozcon.cant_aprobata)*sign(pozcon.pret_promotional)
--	from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
--		con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and 
--		(abs(pozcon.cant_aprobata)-abs(pozcon.pret_promotional)>=0.001 or abs(pozcon.cant_aprobata)>=0.001 and sign(pozcon.cant_aprobata)*sign(pozcon.pret_promotional)<1)) 
	(case 
		when not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
		con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data) 
			then '01' --nu are pozitii
		/*
		when exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
		con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and abs(pozcon.cantitate)>=0.001 and abs(pozcon.cant_aprobata)<0.001) 
			then '0' --exista pozitii cu aprobat=0
		*/
		when not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
		con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and abs(pozcon.cant_aprobata)>=0.001) 
			then '02' --nu exista nici o pozitie aprobata
			
		when not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
		con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and 
		(abs(pozcon.cant_aprobata)-abs(pozcon.cant_realizata)>=0.001 or abs(pozcon.cant_aprobata)>=0.001 and sign(pozcon.cant_aprobata)*sign(pozcon.cant_realizata)<1)) 
			then (case when tip in ('BK', 'BP') then '6' else '6' end) --realizat
			
		when tip='BK' and not exists (select 1 from pozcon where con.subunitate=pozcon.subunitate and con.tip=pozcon.tip and 
		con.contract=pozcon.contract and con.tert=pozcon.tert and con.data=pozcon.data and 
		(abs(pozcon.cant_aprobata)-abs(pozcon.pret_promotional)>=0.001 or abs(pozcon.cant_aprobata)>=0.001 and sign(pozcon.cant_aprobata)*sign(pozcon.pret_promotional)<1)) 
			then (case when tip in ('BK', 'BP') then '4' else '4' end) --expediat/transferat
			
		when tip in ('BK', 'BP') then (case stare when '6' then '1' when '4' then '1' else stare+'0' end)
		else (case stare when '0' then '03' when '3' then '3' else '1' end) -- nerealizat, neexpediat => Operat sau Definitiv
	end)
	from con
where subunitate='1        ' and tip='BK' and data between '01/01/2012' and '30/03/2012' and stare not in ('2', '7')
--and (1=0 or contract='10                  ')
