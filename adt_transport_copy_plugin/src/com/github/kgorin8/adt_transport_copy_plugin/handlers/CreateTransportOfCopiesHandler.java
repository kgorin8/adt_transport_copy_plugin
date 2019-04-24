package com.github.kgorin8.adt_transport_copy_plugin.handlers;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.jface.viewers.ITreeSelection;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.handlers.HandlerUtil;

import com.github.kgorin8.adt_transport_copy_plugin.RequestAction;
import com.github.kgorin8.adt_transport_copy_plugin.TransportOfCopiesRequest;

public class CreateTransportOfCopiesHandler extends AbstractHandler {
	public CreateTransportOfCopiesHandler() {
	}

	public Object execute(ExecutionEvent event) throws ExecutionException {
		IWorkbenchWindow window = HandlerUtil
				.getActiveWorkbenchWindowChecked(event);

		ITreeSelection selection = (ITreeSelection) window
				.getSelectionService().getSelection();
		new TransportOfCopiesRequest(window, selection, RequestAction.Create).executePost();
		return null;
	}
}
