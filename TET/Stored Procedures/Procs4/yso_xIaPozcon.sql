create procedure yso_xIaPozcon @tip char(2)=null as
select * from yso_vIaPozcon v
where ISNULL(@tip,'')='' or v.tip=@tip
