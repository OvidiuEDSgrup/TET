create procedure yso_InlocuireCodMeniu @oldmeniu varchar(20),@newMeniu varchar(20)
as

update webconfigmeniu set Meniu=@newMeniu where meniu=@oldmeniu
update webconfigmeniu set MeniuParinte=@newMeniu where MeniuParinte=@oldmeniu
update webconfiggrid  set Meniu=@newMeniu where meniu=@oldmeniu
update webconfigfiltre set Meniu=@newMeniu where meniu=@oldmeniu
update webconfigtipuri set Meniu=@newMeniu where meniu=@oldmeniu
update webconfigform set Meniu=@newMeniu where meniu=@oldmeniu

update webConfigTaburi set MeniuSursa=@newMeniu where MeniuSursa=@oldmeniu
update webConfigTaburi set MeniuNou=@newMeniu where MeniuNou=@oldmeniu
update webConfigMeniuUtiliz set Meniu=@newMeniu where meniu=@oldmeniu
update WebConfigFormulare set Meniu=@newMeniu where meniu=@oldmeniu
update docfiscale set Meniu=@newMeniu where meniu=@oldmeniu
