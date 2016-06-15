create procedure  [dbo].[wIaPozAngajamenteBugetare] @sesiune varchar(50), @parXML xml  
as

declare @indbug varchar(30), @numar varchar(20), @data datetime,@observatii varchar(50),@stare varchar(1),@explicatii varchar(50)
        ,@compartiment varchar(9),@beneficiar varchar(20),@suma float, @valuta char(3),@curs float
select 
	@indbug=ISNULL(@parXML.value('(/row/@indbug)[1]', 'varchar(20)'), ''),  
	@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),  
	@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), '')  ,	
	@beneficiar= isnull(@parXML.value('(/row/@beneficiar)[1]','varchar(20)'),''),
	@compartiment= isnull(@parXML.value('(/row/@compartiment)[1]','varchar(9)'),''),
	@suma = isnull(@parXML.value('(/row/@suma)[1]','float'),0),
    @valuta = isnull(@parXML.value('(/row/@valuta)[1]','char(3)'),''),
    @curs = isnull(@parXML.value('(/row/@curs)[1]','float'),0),
	@observatii=ISNULL(@parXML.value('(/row/@observatii)[1]', 'varchar(50)'), '') ,
	@explicatii=ISNULL(@parXML.value('(/row/@explicatii)[1]', 'varchar(50)'), '') ,
	@stare=ISNULL(@parXML.value('(/row/@stare)[1]', 'varchar(1)'), '') 	
   

/*select 'Date ang.bug.' as tip_operatie,@numar as numar,convert(char(10), @data, 101) as data,
       rtrim(ltrim(a.observatii))as observatii,convert(varchar, a.data, 101)  as dataR,'#0000FF'as culoare,
       rtrim(a.stare) as stare, 'MA' as subtip, '' as stareC,rtrim(ltrim(a.explicatii))as explicatii,a.indicator as indbug,
       isnull(substring(a.indicator,1,2),'  ')+'.'+isnull(substring(a.indicator,3,2),'  ')+'.'+isnull(substring(a.indicator,5,2),'  ')+'.'+isnull(substring(a.indicator,7,2),'  ')+'.'
       +isnull(substring(a.indicator,9,2),'  ')+'.'+isnull(substring(a.indicator,11,2),'  ')+'.'+isnull(substring(a.indicator,13,2),'  ') as indbug_cu_puncte ,
       (select denumire from lm where cod= a.beneficiar) as denBeneficiar, (select denumire from lm where cod= a.loc_de_munca) as denCompartiment,
       rtrim(a.beneficiar) as beneficiar,rtrim(a.loc_de_munca) as compartiment,convert(decimal(12,3),a.suma) as suma,convert(decimal(12,3),a.curs) as curs,rtrim(a.valuta) as valuta,convert(decimal(12,3),a.suma_valuta) as suma_valuta,
        isnull(substring(i.indbug,1,2),'  ')+'.'+isnull(substring(i.indbug,3,2),'  ')+'.'+isnull(substring(i.indbug,5,2),'  ')+'.'+isnull(substring(i.indbug,7,2),'  ')+'.'
	          +isnull(substring(i.indbug,9,2),'  ')+'.'+isnull(substring(i.indbug,11,2),'  ')+'.'+isnull(substring(i.indbug,13,2),'  ')+' - '+rtrim(ltrim(i.denumire)) 
	   +' -> Suma disponibila: '+
         convert(varchar,((isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p where substring(p.comanda,21,20)=i.indbug 
                                                                                             and p.tip='AO' 
                                                                                             and substring(p.numar,1,7)in ('BA_TRIM')
                                                                                             and datepart(quarter,p.data)<=datepart(quarter,@data)
                                                                                             and year(p.data)=year(@data))),0)+
         isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p where substring(p.comanda,21,20)=i.indbug 
                                                                                             and p.tip='AO' 
                                                                                             and substring(p.numar,1,7)in ('RB_TRIM')
                                                                                             and p.data<=@data
                                                                                             and year(p.data)=year(@data))),0)-                                                                                    
                                                                                                 
         isnull(convert(decimal(12,3),(select sum(suma)from angbug where indicator=i.indbug 
																   and stare>'0'
																   and stare<>'4'
                                                                   and datepart(quarter,data)<=datepart(quarter,@data) 
                                                                   and year(data)=year(@data))),0))))   as denumireAC,''as datam

from angbug a,indbug i 
where a.indicator=@indbug and a.numar=@numar and a.data=@data and i.indbug=a.indicator

--
*/


	select 'Vize-CFP' as tip_viza,r.numar_cfp as numar_CFP,convert(char(10), r.data_CFP, 101) as data,rtrim(ltrim(r.observatii))as observatii,
       convert(varchar, r.data_CFP, 101)  as dataR,'#006400'as culoare--,@stare as stare,'' as subtip,'' as stareC
        
	from registrucfp r 
	where r.indicator=@indbug 
		and r.numar=@numar and r.data=@data
	for xml raw

-- select * from angbug where data='01-05-2009'
