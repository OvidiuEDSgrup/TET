--***
create procedure rapScadentar (@sesiune varchar(50)=null, @cData datetime,@zi1 int, @zi2 int, @zi3 int, @zi4 int, @zi5 int, @zi6 int, @cFurnBenef varchar(1), @cTert varchar(100), @cFactura varchar(100), @cContTert varchar(100))
as
begin
set transaction isolation level read uncommitted
declare @eroare varchar(2000)
begin try
	declare @parXML xml
	select @parXML=(select @sesiune as sesiune for xml raw)
	select datediff(day,f.data_scadentei,@cData) as za,
		(case when datediff(day,f.data_scadentei,@cData)<@zi1 then 1
			when datediff(day,f.data_scadentei,@cData)<@zi2 then 2
			when datediff(day,f.data_scadentei,@cData)<@zi3 then 3
			when datediff(day,f.data_scadentei,@cData)<@zi4 then 4
			when datediff(day,f.data_scadentei,@cData)<@zi5 then 5
			when datediff(day,f.data_scadentei,@cData)<@zi6 then 6
			else 7 end) as TipInterval,
		ft.factura,f.data as data_facturii,f.data_scadentei,
		ft.tert,t.denumire,sum(ft.valoare+ft.tva) as total,sum(ft.achitat) as achitat, '' as explicatii
	from dbo.fFacturi(@cFurnBenef,'01/01/1921',@cData,@cTert,@cFactura,@cContTert,0.01,null,null,null, @parXML) ft 
		left outer join terti t on ft.tert=t.tert and ft.subunitate=t.subunitate
		left outer join facturi f on f.tip=(case when @cFurnBenef='F' then 0x54 else 0x46 end) and f.tert=ft.tert and f.factura=ft.factura and f.subunitate=ft.subunitate
	group by ft.tert,t.tert,ft.factura,f.factura,f.data,f.data_scadentei,t.denumire
		union all 
	select datediff(day,data_scadentei,@cData) as za,
		(case when datediff(day,data_scadentei,@cData)<@zi1 then 1
			when datediff(day,data,@cData)<@zi2 then 2
			when datediff(day,data,@cData)<@zi3 then 3
			when datediff(day,data,@cData)<@zi4 then 4
			when datediff(day,data,@cData)<@zi5 then 5
			when datediff(day,data,@cData)<@zi6 then 6
			else 7 end) as TipInterval,
		factura,data as data_facturii, data as data_scadentei, --data_scadentei,
		p.tert,t.denumire,p.suma as total,0 as achitat, p.explicatii as explicatii
	from prog_plin p
		left outer join terti t on p.tert=t.tert
	where p.tip = case when(@cFurnBenef = 'F') then 'P' else 'I' end and element != 'F'

end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapScadentar '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
