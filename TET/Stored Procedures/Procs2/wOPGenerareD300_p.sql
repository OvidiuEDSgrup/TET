--***
/* procedura pentru populare macheta de generare D300 - decont de TVA */
create procedure wOPGenerareD300_p @sesiune varchar(50), @parXML xml 
as  
declare @data datetime, @luna int, @an int, @subtip varchar(2), 
	@numedecl varchar(150), @prendecl varchar(50), @functiedecl varchar(50), @pro_rata int, @bifa_interne int

exec luare_date_par 'GE', 'NDECLTVA', 0, 0, @numedecl output
exec luare_date_par 'GE', 'FDECLTVA', 0, 0, @functiedecl output
exec luare_date_par 'GE', 'PRORATA', 0, @pro_rata output, 0
exec luare_date_par 'GE', 'D300MSINT', @bifa_interne output, 0, 0

set @data = ISNULL(@parXML.value('(/row/@datalunii)[1]', 'datetime'), ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''))
set @luna = ISNULL(@parXML.value('(/row/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/row/@an)[1]', 'int'), 0)
set @subtip = ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '')

select convert(char(10),@Data,101) as datalunii, @luna as luna, @an as an, rtrim(@functiedecl) as functiedecl, rtrim(LEFT(@numedecl,CHARINDEX(' ',@numedecl)-1)) as numedecl, 
	rtrim(right(rtrim(@numedecl),len(rtrim(@numedecl))-CHARINDEX(' ',rtrim(@numedecl)))) as prendecl,
	@pro_rata as prorata, @bifa_interne as interne, 0 as rambursare
for xml raw, root('Date')

if @subtip in ('ED'/*,'GD'*/)
	SELECT (    
		select convert(char(10),Data,101) as datalunii, rtrim(Rand_decont) as randdecont, RTRIM(denumire_indicator) as denindicator, 
			CONVERT(decimal(10),valoare) as valoare, CONVERT(decimal(10),tva) as tva
		from deconttva p
		where Data=@data
			and Rand_decont not in ('CEREALE','NREVIDPL','RAMBURSTVA')
		order by convert(int,(case when charindex('.',Rand_Decont)<>0 then left(Rand_decont,charindex('.',Rand_Decont)-1) else Rand_decont end))
		FOR XML raw, type  
		) 
	FOR XML path('DateGrid'), root('Mesaje')
