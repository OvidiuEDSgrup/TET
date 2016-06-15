create procedure yso_xIaCon @tip char(2)=null as
select * from yso_vIaCon v
where ISNULL(@tip,'')='' or v.tip=@tip
