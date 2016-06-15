--***
create procedure rapRegistrulBunurilorPrimite
	@sesiune varchar(50)=null,
	@dataj datetime,
	@datas datetime,
	@refacere bit=0,
	@tert varchar(50)=null,
	@cod_material varchar(50)=null,
	@parXML xml=null
as
declare @eroare varchar(max)
select @eroare=''
begin try
	/*
		codul anterior:
			if @refacere=1 exec pregbun @dataj,@datas,@Tert,@cod_material
			select *
			from regbunuri where data_primirii between @dataj and @datas and (rtrim(tert)=rtrim(@Tert) or isnull(@Tert,'')='') 
							and (rtrim(@cod_material)=rtrim(cod_bun) or rtrim(@cod_material)='')
	*/

	
--> jucarie pt raport:
	select top 1000 p.data data_primirii, t.denumire denumire_tert, t.adresa, t.cod_fiscal,
			n.denumire as denumire_bun, p.cantitate cantitate_bun, p.pret_de_stoc*p.cantitate valoare_bun,
				p.cantitate/2  cantitate_ret, p.pret_de_stoc*p.cantitate/2 valoare_ret,
				p.data_facturii data_ret,
				n.grupa denumire_serv, row_number() over (order by (select 1)) as nr_ordine,
				data_operarii data_serviciu
				,p.tert, p.cod as cod_bun, data_operarii data_tr 
		from pozdoc p inner join terti t on p.subunitate=t.subunitate and p.tert=t.Tert
			inner join nomencl n on p.cod=n.cod
		order by data desc

	/*where data_primirii between @dataj and @datas and (@tert is null or rtrim(tert)=rtrim(@Tert))
			and (@cod_material is null or @cod_material=rtrim(cod_bun))
*/
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapRegistrulBunurilorPrimite '+convert(varchar(20),ERROR_LINE())+')'
end catch

	
if len(@eroare)>0 raiserror(@eroare, 16,1)
