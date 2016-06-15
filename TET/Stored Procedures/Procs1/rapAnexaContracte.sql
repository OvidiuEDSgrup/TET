--***
create procedure rapAnexaContracte(@datajos datetime, @datasus datetime,@tert varchar(13),@contract varchar(20), @data_contract datetime, @cod varchar(20), @sursa varchar(13))
as
begin	
	
	select t.tip,rtrim(t.contract) as contract,rtrim(t.tert) as tert,rtrim(p.cod) as cod, rtrim(te.Denumire) as dentert, RTRIM(n.Denumire)as dencod,
		rtrim(p.Mod_de_plata) as sursa, RTRIM(s.Denumire) as densursa, RTRIM(c.LunaAlfa) as luna, RTRIM(c.an) as an,
		t.Cantitate as cantitate,t.Termen,t.Pret,n.UM,(t.Cantitate*t.Pret) as valoare, t.Data as data,
		rtrim(t.Pret)+'/'+n.UM as denpret
	from termene t 
		inner join pozcon p on p.Subunitate=t.Subunitate and p.tip=t.Tip and t.Contract=p.Contract and t.Data=p.data and rtrim(p.Numar_pozitie)=t.Cod
		inner join terti te on te.tert=t.Tert
		inner join nomencl n on n.Cod=p.Cod
		inner join surse s on s.Cod=p.Mod_de_plata
		inner join CalStd c on c.Data=t.Termen
	where t.tip='BF' 
		and(t.Tert=@tert or ISNULL(@tert,'')='')
		and (t.contract=@contract or ISNULL(@contract,'')='')
		and (t.Data=@data_contract or ISNULL(@data_contract,'')='')
		and (p.Cod=@cod or ISNULL(@cod,'')='')
		and (p.Mod_de_plata=@sursa or ISNULL(@sursa,'')='')
		and (t.Termen between @datajos and @datasus)
	order by te.Denumire,t.Data,t.Contract,s.Denumire,n.Denumire,t.Termen
end

/*
select * from termene
*/
