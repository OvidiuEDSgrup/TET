--***
create function solddec (@dData datetime,@cMarca varchar(6),@cDecont varchar(40),@cCont varchar(40)) 
returns float as
begin

 return 
 (select sum(sold) from dbo.fDeconturiCen (null, @dData, @cMarca, @cDecont, 1, 1, @cCont, 0, 0)) 
END
