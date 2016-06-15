--***
create procedure verific_plan_contabil @cont varchar(40) = null
as
begin
	declare @eroare varchar(2000), @enter varchar(20)
	select @eroare='', @cont=rtrim(isnull(@cont,'')), @enter=char(10)+char(13)
	
	declare @arbcnt table (Cont varchar(40) primary key, Cont_parinte varchar(40), sold_debit decimal(20,3), sold_credit decimal(20,3), 
					Are_analitice varchar(1), Tip_cont varchar(1), calculat varchar(1), Denumire_cont varchar(100))
	;with x(cont, cont_parinte, sold_debit, sold_credit, Are_analitice, Tip_cont, calculat, Denumire_cont) as 
	(
	select cont,cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont) from conturi c where c.cont like @cont union all
	select c.cont,c.cont_parinte,0,0,c.Are_analitice,c.Tip_cont,0,rtrim(c.Denumire_cont) from conturi c, x where x.Cont=c.Cont_parinte
	) 
	insert into @arbcnt
	select distinct * from x
	
	select @eroare=rtrim(@eroare)+@enter+rtrim(cont)
	--cont, cont_parinte, 0 sold_debit, 0 sold_credit, Are_analitice, Tip_cont, 
		from @arbcnt c where --rtrim(c.cont) like @cont+'%' and 
			not exists (select 1 from conturi cc where cc.Cont_parinte=c.Cont) and c.Are_analitice=1
	if (@eroare<>'') 
	begin
		set @eroare=@enter+'verific_plan_contabil:'+@enter+
			'Conturile urmatoare sunt configurate gresit! (Nu au analitice, desi sunt configurate sa aiba!) '+char(13)+char(10)+
			'Corectati in planul contabil si reveniti!'+rtrim(@eroare)
		raiserror (@eroare,16,1)
	end
end
