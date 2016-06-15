--***

create procedure rapSituatiepeComenzi @datajos datetime, @datasus datetime,
	@grupa varchar(100)=null, @locm varchar(100)=null, @comanda varchar(100)=null,
	@tip_document varchar(100)=null
	as
begin
	--exec fainregistraricontabile @datasus=@DataSus
	set transaction isolation level read uncommitted
	
	declare @q_datajos datetime, @q_datasus datetime,
		@q_grupa varchar(100), @q_locm varchar(100), @q_comanda varchar(100),
		@q_tip_document varchar(100)
	select @q_datajos=@datajos, @q_datasus=@datasus,
		@q_grupa=@grupa, @q_locm=@locm, @q_comanda=@comanda,
		@q_tip_document=@tip_document
		
	declare @q_eLmUtiliz int
	declare @q_LmUtiliz table(valoare varchar(200), cod_proprietate varchar(100))
	insert into @q_LmUtiliz(valoare, cod_proprietate)
	select * from fPropUtiliz(null) where valoare<>'' and cod_proprietate='LOCMUNCA'
	set @q_eLmUtiliz=isnull((select max(1) from @q_LmUtiliz),0)

	select a.denumire_grupa as den_grupa,p.cont_debitor,p.cont_creditor as cont_creditor,
		(case when p.tip_document='PI' then (case when left(p.explicatii,1)='P' then 'PL' else 'IN' end) else p.tip_document end) as tip_document,
		p.numar_document, p.data, p.suma as suma, p.explicatii,p.loc_de_munca, rtrim(p.comanda) comanda,
		lm.denumire, o.descriere, g.cod_produs as grupacom 
	from pozincon p --left join conturi c on p.cont_debitor=c.cont
		left join lm on lm.cod=p.loc_de_munca
		left join comenzi o on o.comanda=p.comanda
		left join pozcom g on g.subunitate='GR' and g.comanda=p.comanda
		left join grcom a on a.grupa=g.cod_produs
	where
	p.data between @q_datajos and @q_datasus 
		and (@q_locm is null or p.loc_de_munca like @q_locm) and (@q_comanda is null or p.comanda=@q_comanda)
		and (@q_tip_document is null or (case when p.tip_document='PI' then (case when left(p.explicatii,1)='P' then 'PL' else 'IN' end) else p.tip_document end)=@q_tip_document)
		and (@q_grupa is null or g.cod_produs=@q_grupa)
		and (@q_eLmUtiliz=0 or exists (select 1 from @q_LmUtiliz u where u.valoare=p.Loc_de_munca))
	order by g.cod_produs, p.comanda, (case when p.tip_document='PI' then (case when left(p.explicatii,1)='P' then 'PL' else 'IN' end) else p.tip_document end), p.numar_document, p.data
end
