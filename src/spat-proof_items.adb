------------------------------------------------------------------------------
--  Copyright (C) 2020 by Heisenbug Ltd. (gh+spat@heisenbug.eu)
--
--  This work is free. You can redistribute it and/or modify it under the
--  terms of the Do What The Fuck You Want To Public License, Version 2,
--  as published by Sam Hocevar. See the LICENSE file for more details.
------------------------------------------------------------------------------
pragma License (Unrestricted);

package body SPAT.Proof_Items is

   ---------------------------------------------------------------------------
   --  Create
   ---------------------------------------------------------------------------
   overriding function Create (Object : in JSON_Value) return T
   is
      Attempts   : Proof_Attempts.Vector := Proof_Attempts.Empty_Vector;
      Max_Time   : Duration := 0.0;
      Total_Time : Duration := 0.0;
      Check_Tree : constant JSON_Array :=
                     Object.Get (Field => Field_Names.Check_Tree);
   begin
      --  Walk along the check_tree array to find all proof attempts and their
      --  respective times.
      for I in 1 .. GNATCOLL.JSON.Length (Arr => Check_Tree) loop
         declare
            Element : constant JSON_Value :=
                        GNATCOLL.JSON.Get (Arr   => Check_Tree,
                                           Index => I);
         begin
            if
              Preconditions.Ensure_Field (Object => Element,
                                          Field  => Field_Names.Proof_Attempts,
                                          Kind   => JSON_Object_Type)
            then
               declare
                  Attempt_List : constant JSON_Value
                    := Element.Get (Field => Field_Names.Proof_Attempts);

                  procedure Mapping_CB (Name  : in UTF8_String;
                                        Value : in JSON_Value);

                  procedure Mapping_CB (Name  : in UTF8_String;
                                        Value : in JSON_Value) is
                  begin
                     if
                       Proof_Attempts.Has_Required_Fields (Object => Value)
                     then
                        declare
                           Attempt : constant Proof_Attempts.T :=
                                       Proof_Attempts.Create
                                         (Prover => To_Name (Name),
                                          Object => Value);
                        begin
                           Attempts.Append (New_Item => Attempt);

                           Max_Time   := Duration'Max (Max_Time, Attempt.Time);
                           Total_Time := Total_Time + Attempt.Time;
                        end;
                     end if;
                  end Mapping_CB;
               begin
                  GNATCOLL.JSON.Map_JSON_Object (Val => Attempt_List,
                                                 CB  => Mapping_CB'Access);
                  Proof_Attempts.By_Duration.Sort (Container => Attempts);
               end;
            end if;
         end;
      end loop;

      return
        (Entity_Locations.Create (Object => Object) with
             Rule       => Object.Get (Field => Field_Names.Rule),
         Severity   => Object.Get (Field => Field_Names.Severity),
         Attempts   => Attempts,
         Max_Time   => Max_Time,
         Total_Time => Total_Time);
   end Create;

end SPAT.Proof_Items;
