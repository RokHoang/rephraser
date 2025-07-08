-- Test script for Rephraser app
-- This script will automatically test the Cmd+C+C+C functionality

tell application "TextEdit"
    activate
    
    -- Create a new document
    make new document
    
    -- Wait for TextEdit to be ready
    delay 1
    
    -- Type some sample text that needs rephrasing
    set sampleText to "This is a very long and unnecessarily complicated sentence that could definitely be made much shorter and more concise and easier to understand for readers."
    
    tell application "System Events"
        -- Type the sample text
        keystroke sampleText
        
        -- Wait a moment
        delay 0.5
        
        -- Select all text (Cmd+A)
        key code 0 using command down
        
        -- Wait a moment
        delay 0.5
        
        -- Send Cmd+C three times quickly to trigger rephrasing
        key code 8 using command down
        delay 0.1
        key code 8 using command down
        delay 0.1
        key code 8 using command down
        
        -- Wait for the API call and text replacement
        display notification "Testing rephraser... waiting for response" with title "Rephraser Test"
        delay 5
        
        -- Select all text again to see the result
        key code 0 using command down
        delay 0.5
        
        -- Copy the result to clipboard
        key code 8 using command down
        delay 0.5
    end tell
    
    -- Get the clipboard content to check if text was changed
    set resultText to the clipboard
    
    -- Display the results
    if resultText is not equal to sampleText then
        display dialog "✅ SUCCESS: Text was rephrased!" & return & return & "Original: " & sampleText & return & return & "Rephrased: " & resultText buttons {"OK"} default button "OK"
    else
        display dialog "❌ FAILED: Text was not changed" & return & return & "Text: " & resultText buttons {"OK"} default button "OK"
    end if
    
end tell